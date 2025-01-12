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
 node 'ip-172-31-10-8.eu-west-3.compute.internal'{
      include docker
      docker::image { 'ghcr.io/voxpupuli/puppetboard': }
      $puppetdb_host=ip-172-31-8-131.eu-west-3.compute.internal
      docker::run { 'puppetboard':
        image => 'ghcr.io/voxpupuli/puppetboard',
        env   => [
          'PUPPETDB_HOST=$puppetdb_host',
          'PUPPETDB_PORT=8081',
          'PUPPETBOARD_PORT=8088',
          'SECRET_KEY=9d71211996c7aad729da68a49edd61e33209860f68aa4d168e062b31f88e20df',
        ],
        net   => 'host',
      }
      class { 'puppetdb::master::config':
        puppetdb_server => $puppetdb_hostst,
      }
  
  }  
$postgres_host = 'ec2-15-237-251-59.eu-west-3.compute.amazonaws.com'
#Postgres
node 'ip-172-31-12-94.eu-west-3.compute.internal'{
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
    exec {'mv /etc/yum.repos.d/pgdg-redhat-all.repo /etc/yum.repos.d/pgdg-redhat-all.repo.disabled':
     onlyif => ['test -f /etc/yum.repos.d/pgdg-redhat-all.repo'],
    }

  class { 'puppetdb::database::postgresql':
    listen_addresses => $postgres_host,
  }
}

#Puppet db
node 'ip-172-31-8-131.eu-west-3.compute.internal'{
  # Here we install and configure PuppetDB, and tell it where to
  # find the PostgreSQL database.
  firewall { '100 allow http and https access':
    dport  => [22, 8080, 8801],
    proto  => 'tcp',
    jump   => 'accept',
  }
  
  class { 'puppetdb::server':
    database_host => $postgres_host,
  }
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

