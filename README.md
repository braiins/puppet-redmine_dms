# redmine_dms

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with redmine_dms](#setup)
    * [What redmine_dms affects](#what-redmine_dms-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with redmine_dms](#beginning-with-redmine_dms)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Encapsulating module for installation of Redmine and chosen plugins.
Requires Debian Jessie and newer.

## Module Description

It installs all components: Backend DB (PostgreSQL), Redmine,
Redmine plugins, their settings and all dependences.

Configuration of the system side is also provided but no change for
Redmine itself - no touch to its data inside the DB is done.

## Setup

### What redmine_dms affects

* PostgresSQL server and client installation - creation of a database and a user with password owning it.
* Creation of a user the Redmine software to be runing under.
* Using another puppet module to install Redmine itself and the chosen plugins.
* Installs xapian indexer and cron jobs to perform the indexing on regular basis.

### Beginning with redmine_dms

The following snippet shows how to instantiate a Redmine_dms:

```
class { 'redmine_dms':
  redmine_version  => '3.2.0',
  redmine_sys_user => 'redmine',
  redmine_projects => [ 'pr1', 'pr2' ],
  redmine_site     => 'redmine',
  db_name          => 'redmine',
  db_user          => 'redmine',
  db_password      => 'my_pass',
  chklst_vcs_repo  => 'ssh://git@localhost/redmine_checklists.git',
}
```

## Development

Patches and improvements are welcome as pull requests for the central
project github repository.
