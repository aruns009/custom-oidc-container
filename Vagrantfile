#!/usr/bin/env ruby
# vagrant development environment

# read settings file
require "yaml"
cd = File.dirname(__FILE__)
settings = YAML.load_file("#{cd}/provision/settings.yaml")

# check for requried plugins
settings["plugins"].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "Missing plugin! Run: vagrant plugin install #{plugin}"
  end
end unless settings["plugins"].nil? || settings["plugins"].empty?

# check for required env vars
['HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY', 'NEXUS_USERNAME', 'NEXUS_PASSWORD'].each do |var|
  unless ENV[var] || ENV[var] == ""
    raise %{
      Missing #{var} environment variable!
      Export it into your bashrc: echo export #{var}=... >> ~/.bashrc
      Then source the bashrc: source ~/.bashrc
    }
  end
end

Vagrant.configure(2) do |config|

  # virtual box settings
  config.vm.box = settings["box"]
  config.vm.hostname = settings["hostname"]
  config.vm.provider :virtualbox do |vb|
    vb.name = settings["name"]
    vb.memory = settings["memory"]
    vb.cpus = settings["cpus"]
  end

  # synchronise repo with /vagrant
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # internet proxy settings
  config.proxy.http = ENV["HTTP_PROXY"]
  config.proxy.https = ENV["HTTPS_PROXY"]
  config.proxy.no_proxy = ENV["NO_PROXY"]

  # sync user files
  [".bashrc", ".gitconfig", ".ssh/id_rsa", ".ssh/id_rsa.pub", ".ssh/known_hosts"].each do |file|
    config.vm.provision :shell, inline: "rm -f /home/vagrant/#{file}"
    config.vm.provision :file, source: "~/#{file}", destination: "~/#{file}"
    config.vm.provision :shell, inline: "chmod 600 /home/vagrant/#{file}"
  end

  # forward ports
  settings["ports"].each do |port|
    split = port.split(':')
    config.vm.network :forwarded_port, host: split[0], guest: split[1]
  end unless settings["ports"].nil? || settings["ports"].empty?

  # install puppet
  config.vm.provision :shell, inline: <<-SHELL
    if ! type -p puppet >/dev/null 2>&1; then
      rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
      yum install -y puppet-agent
    fi
    FUNCTIONS=/etc/puppetlabs/code/environments/production/lib/puppet/functions
    if [ ! -d $FUNCTIONS ]; then
      mkdir -p $FUNCTIONS
      cp /vagrant/provision/env.rb $FUNCTIONS
    fi
  SHELL

  # install puppet modules
  settings["modules"].each do |mod|
    config.vm.provision :shell, inline: "puppet module install #{mod}"
  end unless settings["modules"].nil? || settings["modules"].empty?

  # apply default puppet manifest
  config.vm.provision :shell, inline: "puppet apply /vagrant/provision/default.pp"

end
