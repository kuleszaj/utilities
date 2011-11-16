puppet master --mkusers
#puppet agent

echo "You should ensure that your intended hostname is properly set, in both /etc/hosts and in your network config."
echo "Currently, the hostname is: $(facter fqdn)"
echo "After this, run: puppet master --mkuser"
