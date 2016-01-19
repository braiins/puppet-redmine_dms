# == Class: redmine_dms
#
# Encapsulating module for installation of Redmine and chosen plugins.
#
# It installs all commponents: Backend DB (PostgreSQL), Redmine,
# Redmine plugins, components and all dependences.
#
# Configuration of the system side is also provided but no change for
# Redmine itself - no touch to its data inside the DB is done.
#
# Requires Debian Jessie and newer.
#
# === Parameters
#
# [*redmine_version*]
#   The desired version of Redmine software to be installed.
#
# [*redmine_sys_user*]
#   User who owns and runs the Redmine application.
#
# [*redmine_projects*]
#   Projects to be indexed by xapian.
#
# [*redmine_site*]
#   Web server's site name, name of the instance.
#
# [*db_name*]
#   Name of the database.
#
# [*db_user*]
#   Database user credentials
#
# [*db_password*]
#   Database user credentials
#
# [*chklst_vcs_repo*]
#   VCS from where the checklist plugin is being cloned from
#
# === Examples
#
# class { '::redmine_dms':
#   redmine_version  => '3.2.0',
#   redmine_sys_user => 'redmine',
#   redmine_projects => [ 'pr1', 'pr2' ],
#   redmine_site     => 'redmine',
#   db_name          => 'redmine',
#   db_user          => 'redmine',
#   db_password      => 'my_pass',
#   chklst_vcs_repo  => 'ssh://git@localhost/redmine_checklists.git',
# }
#
# === Authors
#
# Braiins Systems s.r.o.
#
# === Copyright
#
# Copyright 2016 Braiins Systems s.r.o.
#
class redmine_dms (
  $redmine_version     = $redmine_dms::params::redmine_version,
  $redmine_sys_user    = $redmine_dms::params::redmine_sys_user,
  $redmine_rootdir     = $redmine_dms::params::redmine_rootdir,
  $redmine_projects    = $redmine_dms::params::redmine_projects,
  $redmine_site        = $redmine_dms::params::redmine_site,
  $server_aliases      = $redmine_dms::params::server_aliases,
  $db_name             = $redmine_dms::params::db_name,
  $db_user             = $redmine_dms::params::db_user,
  $db_password         = $redmine_dms::params::db_password,
  $chklst_vcs_repo     = $redmine_dms::params::chklst_vcs_repo,
  $agile_vcs_repo      = $redmine_dms::params::agile_vcs_repo,
  $max_attachment_size = $redmine_dms::params::max_attachment_size,
) inherits redmine_dms::params {

  # DATABASE STAGE

  $timezone = 'UTC'

  class { 'postgresql::globals':
    encoding            => 'UTF8',
    manage_package_repo => false,
    version             => '9.4',
  } ->
  class { 'postgresql::lib::devel':
  } ->
  class { 'postgresql::server':
  } ->
  postgresql::server::config_entry { 'log_timezone':
    value => $timezone,
  } ->
  postgresql::server::config_entry { 'timezone':
    value => $timezone,
  } ->
  # Create database and user/owner in one go
  postgresql::server::db { $db_name:
    user     => $db_user,
    password => $db_password,
  }


  # REDMINE STAGE

  $redmine_dir      = "${redmine_rootdir}/current"

  # Unfortunatelly this causes total freeze of puppet agent process
  # File {
  #   owner => $redmine_sys_user,
  #   group => $redmine_sys_user,
  # }

  class { '::redmine':
    app_root             => $redmine_rootdir,
    redmine_source       => 'https://github.com/redmine/redmine.git',
    redmine_revision     => $redmine_version,
    redmine_user         => $redmine_sys_user,
    db_adapter           => 'pgsql',
    db_name              => $db_name,
    db_user              => $db_user,
    db_password          => $db_password,
    db_port              => '5432',
    require              => Postgresql::Server::Db[$db_name],
  }

  # Redmine plugins dependencies
  package { ['ruby-xapian',
             'libxapian-dev',
             'xpdf',
             'poppler-utils',
             'antiword',
             'catdoc',
             'libwpd-0.10-10',
             'libwps-0.3-3',
             'unrtf',
             'catdvi',
             'djview',
             'djview3',
             'uuid',
             'uuid-dev']:
    ensure => present,
  } ->
  # this package must be installed after the nginx package othervise it installs
  # apache2 being its fallback dependency for a httpd
  package { 'xapian-omega':
    ensure  => present,
    require => Class[nginx],
  } ->

  # Redmine DMSF plugin
  redmine::plugin { 'redmine_dmsf':
    revision        => 'v1.5.5',
    source          => 'https://github.com/danmunn/redmine_dmsf',
    install_command => 'bundle install --path ~/.gem --without development test mysql; bundle exec rake redmine:plugins:migrate RAILS_ENV=production',
  } ->
  file { "${redmine_dir}/plugins/redmine_dmsf/extra/xapian_indexer.rb":
    content => template('redmine_dms/xapian_indexer-dmsf.rb.erb'),
    owner => $redmine_sys_user,
    group => $redmine_sys_user,
    mode => '0755',
    ensure => present,
  } ->
  file { [ "${redmine_dir}/files-dmsf", "${redmine_dir}/dmsf_index" ]:
    owner => $redmine_sys_user,
    group => $redmine_sys_user,
    ensure => directory,
  } ->
  cron { 'Redmine DMSF indexer run':
    command  => "${redmine_dir}/plugins/redmine_dmsf/extra/xapian_indexer.rb -f",
    ensure   => $ensure,
    user     => $redmine_sys_user,
    hour     => '*',
    minute   => '*/5',
    month    => '*',
    monthday => '*',
  } ->

  # Redmine xapian plugin
  redmine::plugin { 'redmine_xapian':
    source          => 'https://github.com/xelkano/redmine_xapian',
    install_command => 'bundle install; bundle exec rake redmine:plugins:migrate RAILS_ENV=production',
  } ->
  file { "${redmine_dir}/plugins/redmine_xapian/extra/xapian_indexer.rb":
    content => template('redmine_dms/xapian_indexer-xapian.rb.erb'),
    owner => $redmine_sys_user,
    group => $redmine_sys_user,
    mode => '0755',
  } ->
  file { "${redmine_dir}/xapian_index":
    owner => $redmine_sys_user,
    group => $redmine_sys_user,
    ensure => directory,
  } ->
  cron { 'Redmine xapian indexer run':
    command  => "${redmine_dir}/plugins/redmine_xapian/extra/xapian_indexer.rb",
    ensure   => $ensure,
    user     => $redmine_sys_user,
    hour     => '*',
    minute   => '*/5',
    month    => '*',
    monthday => '*',
  } ->

  # Redmine checklists plugin
  redmine::plugin { 'redmine_checklists':
    source => $chklst_vcs_repo,
    install_command => 'bundle exec rake redmine:plugins NAME=redmine_checklists RAILS_ENV=production',
  }

  # Redmine agile plugin
  redmine::plugin { 'redmine_agile':
    source => $agile_vcs_repo,
    install_command => 'bundle exec rake redmine:plugins NAME=redmine_checklists RAILS_ENV=production',
  }


  # Web server for Redmine
  if !defined(Class['nginx']) {
    class { 'nginx': }
  }
  redmine::vhost_nginx { "$redmine_site":
    root_dir            => $redmine_rootdir,
    serveraliases       => [ $server_aliases ],
    max_attachment_size => $max_attachment_size,
  }
}
