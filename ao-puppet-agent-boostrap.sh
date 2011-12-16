# Get Rubyforge, install
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm -K rpmforge-release-0.5.2-2.el5.rf.*.rpm
rpm -i rpmforge-release-0.5.2-2.el5.rf.*.rpm

# Get ruby, rubygems, and npdtae
yum install -y glibc gcc-c++ patch make bzip2 autoconf automake libtool bison git subversion readline readline-devel zlib zlib-devel openssl openssl-devel libyaml-devel libffi-devel  ntp

# Run ntpdate to ensure the system date is correct
ntpdate pool.ntp.org


echo "insecure" > ~/.curlrc
# Install RVM
bash < <(curl -k -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

source /etc/profile.d/rvm.sh

rvm install 1.8.7
rvm use 1.8.7 --default

# Update rubygems, and pull down facter and then puppet
gem update --system
gem install facter --no-ri --no-rdoc
gem install puppet --no-ri --no-rdoc

mkdir -p /etc/puppet /var/lib /var/log /var/run
cat >/etc/puppet/puppet.conf <<EOF
[main]
  logdir = /var/log/puppet
  rundir = /var/run/puppet
  ssldir = \$vardir/ssl
  vardir = /var/lib/puppet

  pluginsync = true

  server = "ashnazg.sme.loc"

  environment = "production"
EOF

export PATH="$PATH:/var/lib/gems/1.8/bin"
puppet agent --no-daemonize --onetime --no-splay --verbose --waitforcert 120
echo "On the puppet master, run: puppet cert -s $(facter fqdn)" >&2
echo "When done, press <ENTER>"
read
puppet agent
