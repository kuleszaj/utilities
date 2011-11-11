set -ex

apt-get install ruby rubygems ||
yum install -y ruby rubygems ||
pkgin install ruby rubygems ||
false

gem update --system
gem install facter
gem install puppet

mkdir -p /etc/puppet /var/lib /var/log /var/run
cat >/etc/puppet/puppet.conf <<EOF
[main]
  logdir = /var/log/puppet
  rundir = /var/run/puppet
  ssldir = \$vardir/ssl
  vardir = /var/lib/puppet

  pluginsync = true

  server = "puppet-master-centos.atomicobject.localnet"

  environment = "production"
EOF

export PATH="$PATH:/var/lib/gems/1.8/bin"
puppet agent --no-daemonize --onetime --no-splay --verbose || {
  echo "On the Puppet master, run: puppet cert -s $(facter fqdn)" >&2
  read -p "Press <ENTER> when that's done. " ENTER
  puppet agent --no-daemonize --onetime --no-splay --verbose
}
