group { 'puppet': ensure => present }
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
File { owner => 0, group => 0, mode => 0644 }

class {'apt':
  always_apt_update => true,
}

host { 'home.maniac.in.ua':
    ip => '127.0.0.1',
}

Class['::apt::update'] -> Package <|
    title != 'python-software-properties'
and title != 'software-properties-common'
|>

    apt::key { '4F4EA0AAE5267A6C': }

apt::ppa { 'ppa:ondrej/php5-oldstable':
  require => Apt::Key['4F4EA0AAE5267A6C']
}

class { 'puphpet::dotfiles': }

package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'mc'
  ]:
  ensure  => 'installed',
}

class { 'apache': }

#apache::dotconf { 'custom':
#  content => 'EnableSendfile Off',
#}

#apache::module { 'rewrite': }
apache::module { 'ssl': }

apache::namevhost { "*:8080": ensure => present }
apache::listen { "8080": ensure => present }

apache::vhost { 'home.maniac.in.ua':
  user    => 'vagrant',
  aliases => [
    'home.maniac.in.ua'
  ],
  docroot       => '/var/www/personal/httpdocs',
  ports          => ['*:8080'],
}

class { 'memcached':
  max_memory => 50
}

class { 'php':
  service             => 'apache',
  service_autorestart => false,
  module_prefix       => '',
}

php::module { 'php5-mysql': }
php::module { 'php5-cli': }
php::module { 'php5-curl': }
php::module { 'php5-intl': }
php::module { 'php5-mcrypt': }
php::module { 'php5-memcached': }

class { 'php::devel':
  require => Class['php'],
}

class { 'php::pear':
  require => Class['php'],
}



#$xhprofPath = '/var/www/xhprof'

#php::pecl::module { 'xhprof':
#  use_package     => false,
#  preferred_state => 'beta',
#}

if !defined(Package['git-core']) {
  package { 'git-core' : }
}

#vcsrepo { $xhprofPath:
#  ensure   => present,
#  provider => git,
#  source   => 'https://github.com/facebook/xhprof.git',
#  require  => Package['git-core']
#}

#file { "${xhprofPath}/xhprof_html":
#  ensure  => 'directory',
#  owner   => 'vagrant',
#  group   => 'vagrant',
#  mode    => '0775',
#  require => Vcsrepo[$xhprofPath]
#}


#composer::run { 'xhprof-composer-run':
#  path    => $xhprofPath,
#  require => [
#    Class['composer'],
#    File["${xhprofPath}/xhprof_html"]
#  ]
#}

#apache::vhost { 'xhprof':
#  server_name => 'xhprof',
#  docroot     => "${xhprofPath}/xhprof_html",
#  port        => 80,
#  priority    => '1',
#  require     => [
#    Php::Pecl::Module['xhprof'],
#    File["${xhprofPath}/xhprof_html"]
#  ]
#}


class { 'xdebug':
  service => 'apache',
}

class { 'composer':
  require => Package['php5', 'curl'],
}

puphpet::ini { 'xdebug':
  value   => [
    'xdebug.default_enable = 1',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000'
  ],
  ini     => '/etc/php5/conf.d/zzz_xdebug.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'php':
  value   => [
    'date.timezone = "Europe/Kiev"'
  ],
  ini     => '/etc/php5/conf.d/zzz_php.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'custom':
  value   => [
    'display_errors = On',
    'error_reporting = -1',
    'allow_url_fopen = On',
    'memory_limit = 256M',
    'max_execution_time = 60'
  ],
  ini     => '/etc/php5/conf.d/zzz_custom.ini',
  notify  => Service['apache'],
  require => Class['php'],
}


class { 'mysql::server':
  config_hash   => { 'root_password' => 'mysql' }
}


class { 'phpmyadmin':
  require => [Class['mysql::server'], Class['mysql::config'], Class['php']],
}

apache::vhost { 'phpmyadmin':
  user        => 'vagrant',
  docroot     => '/usr/share/phpmyadmin',
  require     => Class['phpmyadmin'],
}

