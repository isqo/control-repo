## site.pp ##

# This file (./manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
# https://puppet.com/docs/puppet/latest/dirs_manifest.html
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition if you want to use it.

## Active Configurations ##

# Disable filebucket by default for all File resources:
# https://github.com/puppetlabs/docs-archive/blob/master/pe/2015.3/release_notes.markdown#filebucket-resource-no-longer-created-by-default
# File { backup => false }

## Node Definitions ##

# The default node definition matches any node lacking a more specific node
# definition. If there are no other node definitions in this file, classes
# and resources declared in the default node definition will be included in
# every node's catalog.
#
# Note that node definitions in this file are merged with node data from the
# Puppet Enterprise console and External Node Classifiers (ENC's).
#
# For more on node definitions, see: https://puppet.com/docs/puppet/latest/lang_node_definitions.html

$postgres_host = 'ec2-13-38-70-126.eu-west-3.compute.amazonaws.com'
  
node 'ip-172-31-2-128.eu-west-3.compute.internal'{
    Exec { path => "/usr/bin/" }

    exec { 'dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm':
    }
    ->
    exec { 'dnf -qy module disable postgresql ':
    }
    ->
    exec { 'dnf install -y postgresql14-server':
    }
    ->
    exec {'mv /etc/yum.repos.d/pgdg-redhat-all.repo /etc/yum.repos.d/pgdg-redhat-all.repo.disabled':}

  class { 'puppetdb::database::postgresql':
    listen_addresses => $postgres_host,
  }
}

#Puppet server
node 'ip-172-31-10-8.eu-west-3.compute.internal'{

#Quick and dirty change exec root in the future.
Exec { path => "/usr/bin/" }
exec { 'dnf -y update':
 user => root,
}
->
exec { 'dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm':
}
->
exec { 'dnf -qy module disable postgresql ':
}
->
exec { 'dnf install -y postgresql14-server':
}
->
exec {'mv /etc/yum.repos.d/pgdg-redhat-all.repo /etc/yum.repos.d/pgdg-redhat-all.repo.disabled':
 user => root,
}

  # Configure puppetdb and its underlying database
  class { 'puppetdb': }
  
  # Configure the Puppet master to use puppetdb
  class { 'puppetdb::master::config': }
}

node 'ip-172-31-32-167.eu-west-3.compute.internal' {
  class { 'apache': }
}

node 'ip-172-31-42-30.eu-west-3.compute.internal' {
Exec { path => "/usr/sbin" }

  package { 'java-17-openjdk':
    ensure => installed
  }
  ->
  exec { 'alternatives --set java /usr/lib/jvm/java-17-openjdk-17.0.13.0.11-3.el8.x86_64/bin/java':
  }
  include jenkins
  include git
}

node default {
  # This is where you can declare classes for all nodes.
  # Example:
  #   class { 'my_class': }
}

