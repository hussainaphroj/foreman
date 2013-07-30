# Configure the foreman service using passenger
class foreman::config::passenger(

  # specifiy which interface to bind passenger to eth0, eth1, ...
  $listen_on_interface = '',
  $scl_prefix = undef

) inherits foreman::params {
  include apache
  include apache::mod::ssl
  include apache::mod::passenger

# TODO: this is not in use anywhere?
#  if $scl_prefix {
#    class { '::passenger::install::scl':
#      prefix => $scl_prefix,
#    }
#  }

  # Check the value in case the interface doesn't exist, otherwise listen on all interfaces
  if $listen_on_interface in split($::interfaces, ',') {
    $listen_interface = inline_template("<%= @ipaddress_${listen_on_interface} %>")
  } else {
    $listen_interface = '*'
  }

  # Set variables used by vhost template


  if $foreman::params::use_vhost {
	  apache::vhost { 'foreman':
	    template => 'foreman/foreman-vhost.conf.erb',
	    port     => 80,
	    priority => '15',
	    notify   => Service['httpd'],
	    require  => Class['foreman::install'],
	  }  
  } else {
	  file {'foreman_vhost':
	    path    => "${foreman::params::apache_conf_dir}/foreman.conf",
	    content => template('foreman/foreman-apache.conf.erb'),
	    mode    => '0644',
	    notify  => Service['httpd'],
	    require => Class['foreman::install'],
    }    
  }
  


  exec {'restart_foreman':
    command     => "/bin/touch ${foreman::params::app_root}/tmp/restart.txt",
    refreshonly => true,
    cwd         => $foreman::params::app_root,
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { ["${foreman::params::app_root}/config.ru", "${foreman::params::app_root}/config/environment.rb"]:
    owner   => $foreman::params::user,
    require => Class['foreman::install'],
  }
}
