# configures development virtual machine
node 'nginx-oidc.dev.local' {

  include stdlib

  # read settings yaml
  $settings = loadyaml('/vagrant/provision/settings.yaml')
  $packages = $settings[packages]
  $versions = $settings[versions]

  $vagrant_user  = 'vagrant'
  $vagrant_group = 'vagrant'
  $vagrant_home  = "/home/${vagrant_user}"
  $vagrant_bashrc = "${vagrant_home}/.bashrc"

  # install software packages
  package { $packages:
    ensure => present,
  }

  # start in /vagrant
  file_line { 'start-dir':
    path => $vagrant_bashrc,
    line => 'cd /vagrant',
  }

  # install GEP certificate
  package { 'ca-certificates':
    ensure => present,
  }

  file { '/etc/pki/ca-trust/source/anchors/csu.local.crt':
    ensure  => file,
    source  => 'file:///vagrant/provision/csu.local.crt',
    require => Package['ca-certificates'],
  }

  exec { 'update-ca-trust':
    command   => 'update-ca-trust',
    unless    => 'grep "# SubCA01 issuing for CSU.local" /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt',
    path      => ['/usr/local/bin', '/usr/bin'],
    subscribe => File['/etc/pki/ca-trust/source/anchors/csu.local.crt'],
  }

  # parse proxy env vars
  notice("Parsing proxy environment variables")

  $proxy = env('HTTP_PROXY')
  notice("proxy = ${proxy}")

  $no_proxy = env('NO_PROXY')
  notice("no proxy = ${no_proxy}")

  # install docker and docker-compose
  class { 'docker':
    version      => $versions[docker],
    docker_users => [$vagrant_user],
    proxy        => $proxy,
    no_proxy     => $no_proxy,
  }

  # login to docker registry
  $docker = $settings[docker]
  $registries = $docker[registries]
  $nexus_username = env('NEXUS_USERNAME')
  $nexus_password = env('NEXUS_PASSWORD')
  $password_file = "${vagrant_home}/.docker-login"
  notice("nexus username = ${nexus_username}")

  file { $password_file:
    ensure  => file,
    content => $nexus_password,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0400',
  }

  $registries.each |String $registry| {
    exec { "login-${registry}":
      command => "cat ${password_file} | docker login -u ${nexus_username} --password-stdin ${registry}",
      path    => ['/usr/local/bin', '/usr/bin'],
      unless  => "grep '${registry}' $vagrant_home/.docker/config.json",
      require => [Class['Docker'], File[$password_file], Exec['update-ca-trust']],
      user    => 'vagrant',
    }
  }

  class { 'docker::compose':
    version => $versions[compose],
    ensure  => present,
  }

  # alias for docker-compose
  file { '/usr/local/bin/dc':
    ensure => 'link',
    target => '/usr/local/bin/docker-compose',
  }

  # install kubectl
  yumrepo { 'kubernetes-yum-repo':
    ensure        => present,
    descr         => 'Kubectl YUM repository',
    baseurl       => 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64',
    gpgkey        => 'https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
    enabled       => 1,
    gpgcheck      => 1,
    repo_gpgcheck => 1,
  }

  ~> package { 'kubectl':
    ensure => present,
  }

  file { "${vagrant_home}/.kube":
    ensure => directory,
    mode   => '0700',
    owner  => $vagrant_user,
    group  => $vagrant_group,
  }

  file_line { 'kubectl-alias':
    path => $vagrant_bashrc,
    line => 'alias k=kubectl',
  }

  # install helm
  $helm_version = $versions[helm]
  $helm_file = "helm-v${helm_version}-linux-amd64.tar.gz"
  $helm_url = "https://storage.googleapis.com/kubernetes-helm/${helm_file}"
  $helm_dir = "/opt/helm-${helm_version}"
  $helm_exe = "${helm_dir}/helm"

  file { $helm_dir:
    ensure  => directory,
    mode    => '0711',
  }

  ~> archive { $helm_file:
    path            => "/tmp/${helm_file}",
    source          => $helm_url,
    extract         => true,
    extract_path    => $helm_dir,
    extract_command => 'tar xfz %s --strip-components=1',
    creates         => $helm_exe,
    cleanup         => true,
  }

  ~> file { '/usr/bin/helm':
    ensure => 'link',
    target => $helm_exe,
  }
}
