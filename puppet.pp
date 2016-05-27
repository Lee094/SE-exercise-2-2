class puppet () {

	package { [ 'vim-minimal', 'curl', 'git' ]:
		ensure => latest,
		before => User['monitor']
	}
	
	# creates user 'monitor'
	user { 'monitor':
		ensure => 'present',
		home => '/home/monitor/',
		shell => '/bin/bash',
		managehome => true,
		before => File['/home/monitor/scripts/'],
	}

	# creates directory '/home/monitor/scripts/'
	file { '/home/monitor/scripts/':
		ensure => 'directory',
		before => Exec['get_file'],
	}
	
	# downloads memory_check file from github
	exec { 'get_file':
		command => '/usr/bin/wget https://raw.githubusercontent.com/Lee094/SE-exercise-1-2/master/memory_check -O /home/monitor/scripts/memory_check',
		creates => '/home/monitor/scripts/memory_check',
	}

	file { '/home/monitor/scripts/memory_check':
		require => Exec['get_file'],
		before => File['/home/monitor/src/'],
	}

	# creates directory '/home/monitor/src/'
	file { '/home/monitor/src/':
		ensure => 'directory',
	}

	# creates soft link to '/home/monitor/scripts/memory_check'
	file { '/home/monitor/src/my_memory_check':
		ensure => 'link',
		target => '/home/monitor/scripts/memory_check',
		require => File['/home/monitor/src/'],
		alias => 'my_memory_check'
	}

	# parameters for my_memory_check
	$critical = "90"
	$warning = "60"
	$email = "mine@email.com"
	
	# runs my_memory_check every 10 minutes
	cron { 'memory_check':
		ensure => 'present',
		command => "/bin/bash /home/monitor/src/my_memory_check -c $critical -w $warning -e $email",
		minute => '*/10',
		require => File['my_memory_check']
	} 

	# for setting timezone
	package { 'tzdata':
		ensure => 'latest',
	}

	# sets timezone to PHT
	file { '/etc/localtime':
		ensure => 'present',
		source => '/usr/share/zoneinfo/Asia/Manila',
		require => Package['tzdata'],
	}

	# variable for new hostname
	$new_hostname = "bpx.server.local"

	# sets the new hostname
	file_line { 'edit_network':
		ensure => 'present',
		path => '/etc/sysconfig/network',
		line => "HOSTNAME=$new_hostname",
		match => 'HOSTNAME=*',
	}

	exec { 'change_hostname':
		command => "/bin/hostname $new_hostname",
		require => File_line['edit_network'],
	}
}

include puppet

