# Configure foreman
class foreman::config {

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
    group   => $foreman::group,
    mode    => '0640',
    content => template('foreman/database.yml.erb'),
  }

  file { $foreman::init_config:
    ensure  => present,
    content => template("foreman/${foreman::init_config_tmpl}.erb"),
  }

  file { $foreman::app_root:
    ensure  => directory,
  }

  user { $foreman::user:
    ensure  => 'present',
    shell   => '/sbin/nologin',
    comment => 'Foreman',
    home    => $foreman::app_root,
    gid     => $foreman::group,
    groups  => $foreman::user_groups,
  }

  # remove crons previously installed here, they've moved to the package's
  # cron.d file
  cron { ['clear_session_table', 'expire_old_reports', 'daily summary']:
    ensure  => absent,
  }

  if $foreman::passenger  {
    include foreman::config::passenger
  }
}
