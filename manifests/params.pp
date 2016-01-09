# == Class: redmine_dms::params
#
# This class defines default parameters of the main redmine_dms class
#
#
# === Examples
#
# This class is not intended to be used directly.
# It may be imported or inherited by other classes
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2016 Braiins Systems s.r.o.
#
class redmine_dms::params {
  $redmine_version  = '3.2.0'
  $redmine_sys_user = 'redmine'
  $redmine_projects = []
  $redmine_site     = 'redmine'
  $db_name          = undef
  $db_user          = undef
  $db_password      = undef
  $chklst_vcs_repo  = undef
}
