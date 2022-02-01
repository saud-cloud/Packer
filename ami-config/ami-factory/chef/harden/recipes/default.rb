#
# Cookbook:: harden
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe "harden::cis-01.04.03"
#FIXME disable because debian only - make it smart
#include_recipe "harden::cis-05.03.01"
include_recipe "harden::cis-05.03.02"
include_recipe "harden::cis-05.06"
