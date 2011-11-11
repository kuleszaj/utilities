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

echo "You should ensure that the hostname is properly set, in both /etc/hosts and in your network config."
echo "After this, run: puppet master --mkuser"
