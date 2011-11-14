wget http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
rpm -i epel-release-5-4.noarch.rpm

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
