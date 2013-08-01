# Configure foreman
class foreman::config {
  Cron {
    require     => User[$foreman::params::user],
    user        => $foreman::params::user,
    environment => "RAILS_ENV=${foreman::params::environment}",
  }

  concat {'/etc/foreman/settings.yaml':
    owner   => 'root',
    group   => $foreman::params::group,
    mode    => '0640',    
    notify  => Class['foreman::service'],
  }

  concat::fragment {'foreman_settings+01-header.yaml':
    target  => '/etc/foreman/settings.yaml',
    order   => 01,
    content => template('foreman/settings.yaml.erb'),
  }

  file { '/etc/foreman/database.yml':
    owner   => 'root',
    group   => $foreman::params::group,
    mode    => '0640',
    content => template('foreman/database.yml.erb'),
    notify  => Class['foreman::service'],
  }

  case $::operatingsystem {
    Debian,Ubuntu: {
      $init_config = '/etc/default/foreman'
      $init_config_tmpl = 'foreman.default'
    }
    default: {
      $init_config = '/etc/sysconfig/foreman'
      $init_config_tmpl = 'foreman.sysconfig'
    }
  }
  file { $init_config:
    ensure  => present,
    content => template("foreman/${init_config_tmpl}.erb"),
    require => Class['foreman::install'],
    before  => Class['foreman::service'],
  }

  file { $foreman::params::app_root:
    ensure  => directory,
  }

  user { $foreman::user:
    ensure  => 'present',
    shell   => '/sbin/nologin',
    comment => 'Foreman',
    home    => $foreman::params::app_root,
    require => Class['foreman::install'],
  }

  # remove crons previously installed here, they've moved to the package's
  # cron.d file
  cron { ['clear_session_table', 'expire_old_reports', 'daily summary']:
    ensure  => absent,
  }

  if $foreman::params::passenger  {
    class{'foreman::config::passenger':
      listen_on_interface => $foreman::params::passenger_interface,
      scl_prefix          => $foreman::params::passenger_scl,
      ssl                 => $foreman::params::ssl,
    }
  }

}
