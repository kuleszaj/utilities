sudo apt-get update
sudo apt-get install build-essential libxslt1-dev libxml2-dev libreadline-dev zlib1g-dev libssl-dev curl git-core

echo "insecure" > ~/.curlrc
sudo bash -s stable < <(curl -k -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

source /etc/profile.d/rvm.sh

rvmsudo rvm install 1.9.2-p290

source /etc/profile.d/rvm.sh

# Update rubygems, and pull down facter and then puppet
rvmsudo rvm 1.9.2-p290 do gem update --system
rvmsudo rvm 1.9.2-p290 do gem install facter --no-ri --no-rdoc
rvmsudo rvm 1.9.2-p290 do gem install puppet --no-ri --no-rdoc

sudo mkdir -p /etc/puppet /var/lib /var/log /var/run
echo "nameserver 10.138.123.200" > ~/resolv.conf
sudo mv ~/resolv.conf /etc/resolv.conf
cat >~/puppet.conf <<EOF
[main]
  logdir = /var/log/puppet
  rundir = /var/run/puppet
  ssldir = \$vardir/ssl
  vardir = /var/lib/puppet

  pluginsync = true

  server = "isildur.atomicobject.localnet"

  environment = "master"
EOF
sudo mv ~/puppet.conf /etc/puppet/puppet.conf

rvmsudo puppet agent --no-daemonize --onetime --no-splay --verbose --waitforcert 120
