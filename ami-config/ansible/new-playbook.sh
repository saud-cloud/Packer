#!/bin/bash

: ${1:?PlayBook name required}

# think of as 'environment'
# see https://www.digitalocean.com/community/tutorials/how-to-manage-multistage-environments-with-ansible
: ${INVENTORY:="shared production staging devel"}

: ${ROLES:="EXAMPLE"}
: ${CUSTOM:="library module_utils lookup_plugins"}

mkdir "$1"
( cd "$1"

  touch site.yaml
  mkdir $CUSTOM

  mkdir -p {group,host}_vars		#WARN! overrides inventory/*_vars/
  touch {group,host}_vars/all.yaml

  for i in $INVENTORY; do
    mkdir -p inventory/$i
    [ "$1" = 'shared' ] || {
        mkdir -p inventory/$i/{group,host}_vars
        touch inventory/$i/hosts
      }
  done

  for i in $ROLES; do
    mkdir -p roles/"$i"/{tasks,handlers,templates,files,vars,defaults,meta}
    touch roles/"$i"/{tasks,handlers,vars,defaults,meta}/main.yaml
    for j in $CUSTOM; do
        mkdir -p "roles/$i/$j"
    done
  done

)
