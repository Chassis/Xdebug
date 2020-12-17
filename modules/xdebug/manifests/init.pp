# A Chassis extension to install and configure Xdebug on your Chassis server
class xdebug (
	$config,
	$path        = '/vagrant/extensions/xdebug',
	$remote_host  = $config[hosts],
	$php_version  = $config[php],
	$ide          = $config[ide],
	$port         = $config[port]
) {
	$hosts = join($config[hosts],',')

	# Use the SSH client IP for the remote host
	$ssh_ip = generate('/bin/sh', '-c', 'echo $SSH_CLIENT | cut -d "=" -f 2 | awk \'{print $1}\'')

	# For backwards compatibility we'll keep PHPSTORM as the default
	if undef == $ide {
		$ide_name = 'PHPSTORM'
	} else {
		$ide_name = $ide
	}

	if undef == $port {
		$port_number = 9000
	} else {
		$port_number = $port
	}

	if ( ! empty( $config[disabled_extensions] ) and 'chassis/xdebug' in $config[disabled_extensions] ) {
		$package = absent
		$file    = absent
	} else {
		$package = latest
		$file    = 'present'
	}

	if versioncmp( $php_version, '5.6') < 0 {
		package { 'php5-xdebug':
			ensure  => $package,
			require => Package['php5-cli', 'php5-fpm']
		}

		file { '/etc/php5/fpm/conf.d/xdebug.ini':
			ensure  => $file,
			content => template('xdebug/xdebug.ini.erb'),
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => Package['php5-fpm','php5-xdebug'],
			notify  => Service['php5-fpm'],
		}

		file { '/etc/php5/cli/conf.d/xdebug.ini':
			ensure  => $file,
			content => template('xdebug/xdebug.ini.erb'),
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => Package['php5-cli','php5-xdebug'],
		}
	} else {
		package { "php${php_version}-xdebug":
			ensure  => $package,
			require => Package["php${php_version}-fpm", "php${php_version}-cli"],
			notify  => Service["php${php_version}-fpm"],
		}

		file { "/etc/php/${php_version}/fpm/conf.d/xdebug.ini":
			ensure  => $file,
			content => template('xdebug/xdebug.ini.erb'),
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => Package["php${php_version}-fpm","php${php_version}-xdebug"],
			notify  => Service["php${php_version}-fpm"],
		}

		file { "/etc/php/${php_version}/cli/conf.d/xdebug.ini":
			ensure  => $file,
			content => template('xdebug/xdebug.ini.erb'),
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => Package["php${php_version}-cli", "php${php_version}-xdebug"]
		}
	}

	# Export env vars for CLI support
	file_line { 'PHP_IDE_CONFIG':
		path => '/etc/environment',
		line => "PHP_IDE_CONFIG=\"serverName=${hosts}\""
	}
	file_line { 'XDEBUG_SESSION':
		path => '/etc/environment',
		line => "XDEBUG_SESSION=\"${ide_name}\""
	}
}
