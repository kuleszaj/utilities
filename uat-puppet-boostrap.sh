# Get Rubyforge, install
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
sudo rpm -K rpmforge-release-0.5.2-2.el5.rf.*.rpm
sudo rpm -i rpmforge-release-0.5.2-2.el5.rf.*.rpm

# Get ruby, rubygems, and npdtae
sudo yum install -y glibc gcc-c++ patch make bzip2 autoconf automake libtool bison git subversion readline readline-devel zlib zlib-devel openssl openssl-devel libyaml-devel libffi-devel  ntp

# Run ntpdate to ensure the system date is correct
sudo ntpdate pool.ntp.org


echo "insecure" > ~/.curlrc
# Install RVM
sudo bash -s stable < <(curl -k -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

source /etc/profile.d/rvm.sh

rvmsudo rvm install 1.8.7

sudo su - -c 'rvm 1.8.7 --default'

source /etc/profile.d/rvm.sh
rvm 1.8.7 --default

# Update rubygems, and pull down facter and then puppet
rvmsudo gem update --system
rvmsudo gem install facter --no-ri --no-rdoc
rvmsudo gem install puppet --no-ri --no-rdoc

sudo mkdir -p /etc/puppet /var/lib /var/log /var/run
cat >~/puppet.conf <<EOF
[main]
  logdir = /var/log/puppet
  rundir = /var/run/puppet
  ssldir = \$vardir/ssl
  vardir = /var/lib/puppet

  pluginsync = true

  server = "ashnazg.sme.loc"

  environment = "uat"
EOF
sudo mv ~/puppet.conf /etc/puppet/puppet.conf

echo "On the puppet master, run: puppet cert -s $(facter fqdn)" >&2
echo "When done, press <ENTER>"
rvmsudo puppet agent --no-daemonize --onetime --no-splay --verbose --waitforcert 120
read
rvmsudo puppet agent
