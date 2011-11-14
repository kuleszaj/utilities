# Get Rubyforge, install
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm -K rpmforge-release-0.5.2-2.el5.rf.*.rpm
rpm -i rpmforge-release-0.5.2-2.el5.rf.*.rpm

# Get ruby, rubygems, and npdtae
yum install -y glibc gcc-c++ patch make bzip2 autoconf automake libtool bison git subversion readline readline-devel zlib zlib-devel openssl openssl-devel libyaml-devel libffi-devel  ntp

# Run ntpdate to ensure the system date is correct
ntpdate pool.ntp.org

# Install RVM
bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

/usr/local/rvm/bin/rvm install 1.8.7
/usr/local/rvm/bin/rvm use 1.8.7 --default

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
EOF

# Add firewall rule to allow puppet agent connections
iptables -I INPUT 1 -p tcp --dport 8140 -j ACCEPT

# Save firewall configure
OS=`facter osfamily`
OS=`echo $OS | tr [:upper:] [:lower:]`
case $OS in
  "redhat")
    echo "Detected Redhat Family"
    iptables-save > /etc/sysconfig/iptables
    ;;
  "debian")
    echo "Detected Debian Family"
    iptables-save > /etc/iptables.rules
    ;;
  *)
    echo "Uknown OS"
    ;;
esac

echo "You should ensure that your intended hostname is properly set, in both /etc/hosts and in your network config."
echo "Currently, the hostname is: $(facter fqdn)"
echo "After this, run: puppet master --mkuser"

