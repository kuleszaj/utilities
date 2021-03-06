mkdir -p /home/git/etc/puppet/environments
cat >/home/git/repositories/puppet-smetoolkit.git/hooks/post-receive <<EOF
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

chmod +x /home/git/repositories/puppet-smetoolkit.git/hooks/post-receive
chown -R git:git /home/git/

echo "You should now commit all of the necessary files to the puppet-smetoolkit repo, and then run:"
echo "Run: bash < <(curl https://raw.github.com/kuleszaj/utilities/master/ao-puppet-master-bootstrap-part3.sh)"
