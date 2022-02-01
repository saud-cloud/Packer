# Introduction
This is a collection of re-usable templates intended for use in creating tailored Machine Images.
It is intended to be used across clients with their configuration data kept in a separate repo.
The main driver is Packer.IO but any similar tool can be leveraged in the future if so desired.

# Tools

## Packer.IO
The provisioners can be used to run Ansible, Chef, Puppet or other customization software to
bake a configuration into the resulting image. If at all possible the manifests/recipes/plays
should be written in a broadly compatible manner so the codebase can be re-used. Client or 
Environment-specific settings should be injected via Hiera, environment variables, or Attributes
or the codebase branched if the changes are too extensive and don't lend themselves to simple
overrides.

## YamlReader
This [tool](https://github.com/tb3088/yamlreader) reads in YAML or JSON fragments to combine,
potentially key-merge, and emit as either format. The Packer parser is rather limited and for
any sufficiently complicated template, a pre-processor can be very helpful.

## Chef

## Ansible

# Usage
1. Populate `ami-config` repository with configuration fragments and compose a configuration file.
2. Symlink a file matching the configuration filename to the `create-image.sh` wrapper.
3. Run the script.

# Example
