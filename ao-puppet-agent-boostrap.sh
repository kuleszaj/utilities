# Get ruby, rubygems, and npdtae
apt-get install ruby rubygems ntpdate ||
yum install -y ruby rubygems ntpdate ||
false

# Run ntpdate to ensure the system date is correct
ntpdate pool.ntp.org

# Update rubygems, and pull down facter and then puppet
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
echo "Ensure that puppet-master-centos.atomicobject.local is accessible, then:"
echo "On this machine run: puppet agent --no-daemonize --onetime --no-splay --verbose"
echo "On the puppet master, run: puppet cert -s $(facter fqdn)" >&2
echo "When that's done, on this machine run: puppet agent --no-daemonize --onetime --no-splay --verbose"
