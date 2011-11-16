# Get Rubyforge, install
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm -K rpmforge-release-0.5.2-2.el5.rf.*.rpm
rpm -i rpmforge-release-0.5.2-2.el5.rf.*.rpm

# Get ruby, rubygems, and npdtae
yum install -y glibc gcc gcc-c++ patch make bzip2 autoconf automake libtool bison git subversion readline readline-devel zlib zlib-devel openssl openssl-devel libyaml-devel libffi-devel  ntp

# Run ntpdate to ensure the system date is correct
ntpdate pool.ntp.org

# Install RVM
bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

source /etc/profile.d/rvm.sh

/usr/local/rvm/bin/rvm install 1.8.7
/usr/local/rvm/bin/rvm use 1.8.7 --default

# Update rubygems, and pull down facter and then puppet
gem update --system
gem install facter --no-ri --no-rdoc
gem install puppet --no-ri --no-rdoc

source /etc/profile.d/rvm.sh

mkdir -p /etc/puppet/environments /var/lib /var/log /var/run
cat >/etc/puppet/puppet.conf <<EOF
[main]
  logdir = /var/log/puppet
  rundir = /var/run/puppet
  ssldir = $vardir/ssl
  vardir = /var/lib/puppet
  pluginsync = true
[agent]
  report = true
  show_diff = true
  pluginsync = true
  environment = mst
[prd]
  manifest = /etc/puppet/environments/prd/manifests/site.pp
  modulepath = /etc/puppet/environments/prd/modules
[uat]
  manifest = /etc/puppet/environments/uat/manifests/site.pp
  modulepath = /etc/puppet/environments/uat/modules
[dev]
  manifest = /etc/puppet/environments/dev/manifests/site.pp
  modulepath = /etc/puppet/environments/dev/modules
[mst]
  manifest = /etc/puppet/environments/mst/manifests/site.pp
  modulepath = /etc/puppet/environments/mst/modules
EOF

# Add firewall rule to allow puppet agent connections
iptables -I INPUT 1 -p tcp --dport 8140 -j ACCEPT

# Save firewall configure
OS=`source /etc/profile.d/rvm.sh && rvm 1.8.7 && facter osfamily`
FQDN=`source /etc/profile.d/rvm.sh && rvm 1.8.7 && facter fqdn`
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
    echo "Unknown OS"
    ;;
esac

useradd -m -s /bin/bash git
useradd -m -s /bin/bash puppet
su - git -c 'git clone git://github.com/sitaramc/gitolite'
su - git -c '~/gitolite/src/gl-system-install'
cat >/home/git/pps.pub <<EOF
ssh-dss AAAAB3NzaC1kc3MAAACBAMHRmXb9OoWuUbVNh4BJ2tUhVcZXRXfKGcnICgSXxm2KZssUGI5OWKMQlIOpNTTJtMa7wD7KjVndlFYTJonFt205VwJI9c4ybmNLHKkCpDmnRdbCOPHIFs7fai/9hQDv5etZ8V3BoGREieGyZaUGAJUuge3uU5jhV/wb90btumHxAAAAFQCGGHtR1NzGPjyaCmynfZaaQdRFFwAAAIAtg3HMybg3rxhsQv/fxi++T17zIAJ1zVwY62ZVGEBoM73+MHQt9aZxQTgEomyaUsFCvSHl+U6RW9SWa5vD/jz1XobgR5Kawe+e3z4FLu2dJolZpZ52B1+gbA10NgBdLKP/joSo3elubVZUqOmxmRpTlY+IMogQwU3wmKTaKV0JCAAAAIByr29YkxN8RW8zBy28A+7NOf64LLkjIMhk+6m5HlYvypsg/WHDXQ9dgJVG3205wOBxAXjnFKASnw6V0EQEsgS/nXGgtNlV/gGrAwEr5+uvicUkZ3DNFymBeqDkPC6MIwsc2ap4mbkCWouv8SG2xbsGQwqCeOvVPK5zK0/zu+kTNw==
EOF
su - git -c 'gl-setup -q ~/pps.pub'

echo -e "git  ALL=(root)  NOPASSWD: /bin/mv -f /home/git/etc/puppet/environments/* /etc/puppet/environments\ngit ALL=(root)  NOPASSWD: /bin/chown -R puppet\\:puppet /etc/puppet/environments\ngit ALL=(root)  NOPASSWD: /bin/rm -rf /etc/puppet/environments*\nDefaults  !requiretty" >> /etc/sudoers
echo "You now must clone the gitolite administration repository, and create the new repository for the puppet code."
echo "Run: git clone git@$FQDN:gitolite-admin"
echo "Create a new repo named 'puppet-smetoolkit' and then..."
echo "Run: bash < <(curl https://raw.github.com/kuleszaj/utilities/master/ao-puppet-master-bootstrap-part2.sh)"

