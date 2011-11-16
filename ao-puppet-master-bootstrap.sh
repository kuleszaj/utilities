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

useradd -m -s /bin/bash git
su - git -c 'git clone git://github.com/sitaramc/gitolite'
su - git -c '~/gitolite/src/gl-system-install'
cat >/home/git/pps.pub <<EOF
ssh-dss AAAAB3NzaC1kc3MAAACBAMHRmXb9OoWuUbVNh4BJ2tUhVcZXRXfKGcnICgSXxm2KZssUGI5OWKMQlIOpNTTJtMa7wD7KjVndlFYTJonFt205VwJI9c4ybmNLHKkCpDmnRdbCOPHIFs7fai/9hQDv5etZ8V3BoGREieGyZaUGAJUuge3uU5jhV/wb90btumHxAAAAFQCGGHtR1NzGPjyaCmynfZaaQdRFFwAAAIAtg3HMybg3rxhsQv/fxi++T17zIAJ1zVwY62ZVGEBoM73+MHQt9aZxQTgEomyaUsFCvSHl+U6RW9SWa5vD/jz1XobgR5Kawe+e3z4FLu2dJolZpZ52B1+gbA10NgBdLKP/joSo3elubVZUqOmxmRpTlY+IMogQwU3wmKTaKV0JCAAAAIByr29YkxN8RW8zBy28A+7NOf64LLkjIMhk+6m5HlYvypsg/WHDXQ9dgJVG3205wOBxAXjnFKASnw6V0EQEsgS/nXGgtNlV/gGrAwEr5+uvicUkZ3DNFymBeqDkPC6MIwsc2ap4mbkCWouv8SG2xbsGQwqCeOvVPK5zK0/zu+kTNw==
EOF
su - git -c 'gl-setup -q ~/pps.pub'

echo "You now must clone the gitolite administration repository, and create the new repository for the puppet code."
echo "Run: git clone git@$(facter fqdn):gitolite-admin"
read -p "Provide the name of the new repository (no quotes, no spaces), and hit (ENTER):" reponame

echo -e "git  ALL=(root)  NOPASSWD: /bin/mv -f /home/git/etc/puppet/environments/* /etc/puppet/environments\ngit ALL=(root)  NOPASSWD: /bin/chown -R puppet\\:puppet /etc/puppet/environments\ngit ALL=(root)  NOPASSWD: /bin/rm -rf /etc/puppet/environments*" >> /etc/sudoers

cat >/git/home/repositories/$(reponame).git/hooks/post-receive <<EOF
#!/usr/bin/env ruby
 
# Set this to where you want to keep your environments
ENVIRONMENT_BASEDIR = "/home/git/etc/puppet/environments"
FINAL_BASEDIR = "/etc/puppet/environments"
 
# post-receive hooks set GIT_DIR to the current repository. If you want to
# clone from a non-local repository, set this to the URL of the repository,
# such as git@git.host:puppet.git
SOURCE_REPOSITORY = File.expand_path(ENV['GIT_DIR'])
 
# The git_dir environment variable will override the --git-dir, so we remove it
# to allow us to create new repositories cleanly.
ENV.delete('GIT_DIR')
 
# Ensure that we have the underlying directories, otherwise the later commands
# may fail in somewhat cryptic manners.
unless File.directory? ENVIRONMENT_BASEDIR
  puts %Q{#{ENVIRONMENT_BASEDIR} does not exist, cannot create environment directories.}
  exit 1
end
 
# You can push multiple refspecs at once, like 'git push origin branch1 branch2',
# so we need to handle each one.
\$stdin.each_line do |line|
  oldrev, newrev, refname = line.split(" ")
 
  # Determine the branch name from the refspec we're received, which is in the
  # format refs/heads/, and make sure that it doesn't have any possibly
  # dangerous characters
  branchname = refname.sub(%r{^refs/heads/(.*$)}) { \$1 }
  if branchname =~ /[\W-]/
    puts %Q{Branch "#{branch}" contains non-word characters, ignoring it.}
    next
  end
 
  environment_path = "#{ENVIRONMENT_BASEDIR}/#{branchname}"
  final_path = "#{FINAL_BASEDIR}/#{branchname}"
 
  if newrev =~ /^0+$/
    # We've received a push with a null revision, something like 000000000000,
    # which means that we should delete the given branch.
    puts "Deleting existing environment #{branchname}"
    if File.directory? environment_path
      FileUtils.rm_rf environment_path, :secure => true
    end
  else
    # We have been given a branch that needs to be created or updated. If the
    # environment exists, update it. Else, create it.
 
    if File.directory? environment_path
      # Update an existing environment. We do a fetch and then reset in the
      # case that someone did a force push to a branch.
 
      puts "Updating existing environment #{branchname}"
      Dir.chdir environment_path
      %x{git fetch --all}
      %x{git reset --hard "origin/#{branchname}"}
      %x{sudo -u root /bin/rm -rf #{final_path}}
      %x{sudo -u root /bin/mv -f #{environment_path} #{FINAL_BASEDIR}}
      %x{sudo -u root /bin/chown -R puppet:puppet #{FINAL_BASEDIR}}
    else
      # Instantiate a new environment from the current repository.
 
      puts "Creating new environment #{branchname}"
      %x{git clone --no-hardlinks #{SOURCE_REPOSITORY} #{environment_path} --branch #{branchname}}
      %x{sudo -u root /bin/rm -rf #{final_path}}
      %x{sudo -u root /bin/mv -f #{environment_path} #{FINAL_BASEDIR}}
      %x{sudo -u root /bin/chown -R puppet:puppet #{FINAL_BASEDIR}}
    end
  end
end
EOF

chmod +x /git/home/repositories/$(reponame).git/hooks/post-receive
chown git:git /git/home/repositories/$(reponame).git/hooks/post-receive

read -p "Add manifests to the new $(reponame), commit, push, and then (ENTER):"

puppet master --mkusers
#puppet agent

echo "You should ensure that your intended hostname is properly set, in both /etc/hosts and in your network config."
echo "Currently, the hostname is: $(facter fqdn)"
echo "After this, run: puppet master --mkuser"

