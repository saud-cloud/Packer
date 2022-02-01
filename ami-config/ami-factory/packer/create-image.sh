#!/bin/env bash

#FIXME, why does script exit quickly if 'OS_*' are set?

function Usage() {
    >&2 cat << _EOF

  ${BASH_SOURCE##*/} <cmd=validate> [options] [packer_opts] <template>

  build:
    -A  <AWS_PROFILE>
#    -k <keystore>

   #  -1, -parallel=false
    -parallel-builds=1
    -d, -debug
    -n, -noop
    -p, -on-error=ask
    -v, -verbose

  validate:
    -t, -syntax-only

  inspect:

  <shared>
    -c  <config_file>
    -I  <image> (eg. AMI)
    -E  <environment>
    -L  <layer>
    -P  <project>
    -R  <role>
    -G  <AWS_REGION>
    -T  <template>

----------
    cmd         ::= build | inspect | validate
                    (FUTURE: version|push|fix)
    environment ::= development | qa | production
    layer       ::= base | app | data | tools | edge | ... ???
    region      ::= us-east-1 | ...
                        http://docs.aws.amazon.com/general/latest/gr/rande.html

# https://www.packer.io/docs/command-line/build.html
_EOF
    exit 2
}

#FIXME why not use convert_path()?
function path2dos() {
  # cygpath does not recognize escaped spaces, so remove the slash
  [[ "${OSTYPE:-`uname -o`}" == [cC]ygwin || `which cygpath &>/dev/null` ]] &&
      cygpath -w -- "${1//\\ / }" 2>/dev/null ||
      echo "$1"
}

# Do a quick search for a file. $2+ are sub-directories to search
function findfile() {
  local suffix=('' .{var,json})
  local file dir sfx

  [ "${1:0:1}" = '/' ] && { path2dos "$1"; return; }

  for dir in "${@:2}" \.; do
    for sfx in "${suffix[@]}"; do
        file="$dir/$1$sfx"
        [ -f "$file" ] && { path2dos "$file"; break 2; }
    done
  done
}

[ "${TERM#screen}" = "$TERM" ] || {
    # mossc 2019_09_20
    echo  "WARNING using CTRL-C to abort Packer will wedge under Screen!"
    echo  "hit return to continue despite warning or cntl-c now to exit"
    read junk
    #exit 1
  }


# ---- Main ----

_prog="${BASH_SOURCE##*/}"
_progdir=$( cd `dirname "$BASH_SOURCE"`; pwd )
_PROG=`readlink -qe "$BASH_SOURCE"` || {
    # impossible error
    >&2 echo "ERROR: $0 has broken link component"; exit 1
  }
_PROGDIR="${_PROG%/*}"          # or `dirname "$_PROG"`
_PROG="${_PROG##*/}"            # or `basename "$_PROG"`

source "$_PROGDIR/functions" || return

: ${PACKER:=`which packer`}
#case `"$PACKER" --version 2>/dev/null` in
#  1.[236*)
#        ;;
#  *)    error "${PACKER:-Packer.IO} not found or too old"
#esac

# --- global variables ---
: ${CLOUD:=aws}                 # assume AWS
declare -a cmd args _save
: ${BASEDIR:=${_PROGDIR%/*}}

# --- process arguments ---
_GETOPT='hA:B:c:G:I:L:P:R:T:'

case "$1" in
  build)
        _GETOPT+='1dnp'
        ;;&
  validate)
        _GETOPT+='t'
        ;;&
  build|validate|inspect)
        cmd=("$1")
        shift
        ;;
  help) Usage ;;
  fix|push|version)
        notice "unsupported command ($1)"
        "$PACKER" "$@"
        exit
        ;;
  -*)   ;;
  *)  RC=2 error "unknown command (${1:?})"
esac

# Settings priority order: defaults < config file < environment < cmdline switch
# HOWEVER that is incumbant on a properly written CONFIG file! To help out '-c'
# is processed immediately, so should be specified early on.
#
#TODO use silent mode '^:'
while getopts ":$_GETOPT" sw; do
  case "$sw" in
    1)  cmd+=('-parallel-builds=1') ;;
#    a)  eval ${CLOUD^^}_PROFILE=${OPTARG} ;;
    A)  PROFILE="$OPTARG" ;;
    B)  BUILDER="$OPTARG" ;;
    c)  CONFIG="$OPTARG"
        # process immediately in lame attempt at priority
        source "$CONFIG" || error "loading file ($CONFIG)";
        ;;
    d)  : ${DEBUG:=1} ;;
#    E) ENVIRON=$"OPTARG" ;;
    G)  REGION="$OPTARG" ;;
    I)  IMAGE="$OPTARG" ;;
#     k)  KEYSTORE="$OPTARG" ;;
    L)  LAYER="$OPTARG" ;;
    n)  NOOP=1 ;;
    P)  PROJECT="$OPTARG" ;;
    p)  cmd+=('-on-error=ask') ;;
    R)  ROLE="$OPTARG" ;;
    T)  TEMPLATE="${OPTARG}" ;;
    t)  cmd+=('-syntax-only') ;;
    h)  Usage ;;
    # TODO support double-dash long options and mangle to Packer's retarded single-dash format
    \?) sw=${@:$OPTIND:1}
        case $sw in
          '-var')
                args+=( '-var' "${@:$((++OPTIND)):1}" )
                ;;
          '-var-file')  # useful distinction?
                _save+=( '-var-file'="${@:$((++OPTIND)):1}" )
                ;;
          '-var-file='*)
                _save+=( "${@:$((OPTIND++)):1}" )
                ;;
          '--') break ;;        # stop processing
          '-'*) # assume program option
                cmd+=( "${@:$((OPTIND++)):1}" )
        esac
        ;;
    :)  RC=2 error "missing argument (-$OPTARG)" ;;
    *)  RC=2 warn "unhandled option (-$sw) "
  esac
done
shift $((OPTIND-1))

# Use (external) directories to break out multiple configurations as opposed
# to in-tree branches for simpler management and code re-use.
if [ -z "$CONFIG" -a "${_prog%.sh}" != "${_PROG%.sh}" ]; then
  _file="$_progdir/${_prog%.sh}.conf"
  [ -f "$_file" ] && { source "$_file" || error "loading Config ($_file)"; }
fi

if [ -z "$TEMPLATE" ]; then
  [ $# -ge 1 ] || RC=2 error "insufficient args - missing 'TEMPLATE'"

  TEMPLATE="${@: -1}"           # assign last element and trim
  set -- "${_save[@]}" "${@:1:$#-1}"
fi


if [ -n "$DEBUG" ]; then
  #cmd+=('-debug' '-parallel-builds=1')
  # mossc 2019_09_19
  #cmd+=('-debug' '-parallel-builds=1' '-on-error=ask' )
  # mossc 2020_09_18
  cmd+=('-debug')
  [ ${DEBUG:-0} -gt 1 ] && PACKER_LOG=1
fi

#cmd+=('-debug' '-parallel-builds=1' '-on-error=ask' )
cmd+=('-timestamp-ui' '-parallel-builds=1' '-on-error=ask' )

[[ "$-" =~ i || -n "$PS1" ]] || PACKER_NO_COLOR=true
export ${!PACKER_*}

${ABORT:+ set -e}

#TODO
# for env in {PUPPET,CHEF,}_ENV; do
  # # set but empty '' is considered valid?
  # [ "${!env-unset}" = 'unset' ] || continue
  # : ${_ENV:=${!env}}
  # break
# done
# case "${_ENV:=production}" in
  # dev*)
      # _ENV=development
      # ;;
  # qa) ;;
  # prod*)
      # _ENV=production
      # ;;
  # *)  echo "ERROR: unknown environment ($_ENV)"
      # Usage
# esac


# Process *REGION environment
for k in ${CLOUD^^}_{{,DEFAULT_}REGION,PROFILE} ; do
  [ -n "${!k}" ] || continue
  case $k in
    ${CLOUD^^}_*REGION)
        : ${REGION:=${!k}}
        ;;
    AWS_PROFILE)                # see aws-profile() in .bashrc_aws
        : ${REGION:=`aws configure get region --profile "$AWS_PROFILE" 2>/dev/null`}
        ;;
    *)  warn "unsupported option ($k)"
  esac
done
#TODO
# [ -n "$REGION" ] || {
  # case ${CLOUD^^} in
    # AWS)
        # local default=`curl -s 'http://169.254.169.254/latest/meta-data/placement/availability-zone' | sed -e 's/[a-z]$//'`
        # local choices=(`aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text --region us-east-1 | sort`)
        # if prompt, display selection with numbers or simple menu, with default 
        # ;;
    # *)
  # esac
  # while prompt < "${options[@]}"
# }
REGION=${REGION/%[a-z]/}


# FIXME shouldn't need a local Ruby environment to create images
#
# process kitchen/Berksfile
#[ -d "$CHEF_BASEDIR" ] && (
#  cd "$CHEF_BASEDIR"
#  set -- $cmd
#  [ "$1" = 'build' ] &&
#    ${DEBUG:+runv} berks vendor cookbooks >/dev/null
#)


( cd "${PACKER_BASEDIR:-$_progdir}"

  # try to be clever about finding 'var-file's from cmdline switches
  for k in VARFILES BUILDER REGION IMAGE PROJECT LAYER ROLE; do
    [ -n "${!k}" ] || continue

    for p in `eval echo "\\${$k[@]}"`; do
      _vfile=`findfile "$p" "${k,,}"`
      debug "$p\tfound $_vfile"
      # anything found is a var file by definition
      # BUG!!  Packer can't handle quotes on RHS of '=' therefore NO spaces in path name allowed!
      #FIXME use `join_string` with escape=1
      [ -n "${_vfile}" ] && args+=( "-var-file=${_vfile}" )
    done
  done

  # Define some Environment variables as Packer template vars - allows the template
  # to enforce presence with 'null' because using {{env `XYZ`}} doesn't catch unset/empty.
  #
  # TODO: Shell/File provisioners could benefit but not visible to the Templates!
  for v in BASEDIR ${DIRS[@]}; do
    [ -n "${!v}" ] || continue
    [ -d "${!v}" ] && _path=`path2dos "${!v}"` || _path=
#  #XXX how does Packer/GoLang deals with spaces in pathspec?
#  # _path="${_path// /\\ }"

    _v=${v/_/.}                 # NOTE: template must match naming convention!
    args+=('-var' "${_v,,}=${_path:-${!v}}")
  done

  # assumes array elements are 'key=value'
  for k in ${VARS[@]}; do args+=('-var' "$k"); done

  # WARNING spaces not supported
  for k in ${!VARMAP[@]}; do args+=('-var' "$k=${VARMAP[$k]}"); done

  # process left over command-line args
  while [ "${1+x}" ]; do
    # deal with empty string, rare but possible
    [ -n "$1" ] || { shift; continue; }
    _vfile=

    # only '-var-file=*' should ever fire since 'buried' options are improper
    case "$1" in
      '-var')
            args+=('-var' "$2")
            shift 2; continue
            ;;
      '-var-file')
            _vfile=`findfile "$2"`
            shift
            ;&
      '-var-file='*)
            : ${_vfile:=`findfile "${1#*=}"`}
            [ -n "$_vfile" ] || error "file not found (${1#*=})"
            args+=(-var-file="${_vfile}")
            shift; continue
            ;;
      '--') shift; break        # stop processing
            ;;
      '-'*) # assume program option
            args+=("$1")        # TODO prepend?
            shift; continue
    esac

    _left="${1%%=*}"
    _right="${1#*=}"
    if [ "$_left" != "$_right" ]; then
      # implicit key=value
      args+=('-var' "$1")
    else
      # implicit -var-file
      _vfile=`findfile "$_right"`
      [ -n "$_vfile" ] && args+=(-var-file="${_vfile}") || warn "implicit var-file not found ($_right)"
    fi
    shift
  done

  # influence ANSIBLE_DEFAULT_VERBOSITY etc. but must be an integer
  # VERBOSE is additive by DEBUG
  declare -i _level=0
  for v in DEBUG VERBOSE; do
    _level+=`printf "%d" ${!v} 2>/dev/null` || _level+=1
    args+=('-var' "provision.${v,,}=$_level")
  done

# mossc 2019_09_25
#echo "exiting without actually running packer"
#echo ${DEBUG:+runv} ${NOOP:+ echo} "${PACKER:?}" "${cmd[@]}" "${args[@]}" `path2dos "$TEMPLATE"` > /tmp/ci.run
#exit 1

  ${DEBUG:+runv} ${NOOP:+ echo} "${PACKER:?}" "${cmd[@]}" "${args[@]}" `path2dos "$TEMPLATE"`
)

# vim: expandtab:ts=4:sw=4
