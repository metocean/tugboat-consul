require 'shelljs/global'

# Link node
ln '-s', '/usr/bin/nodejs', '/usr/bin/node'

# Disable ssh
rm '-rf', '/etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh'

# Install tugboat-consul
exec 'npm install -g tugboat-consul tugboat ducke'
cp '-R', 'tugboat', '/tugboat'
mkdir '/etc/service/tugboat'
cp 'tugboat/run.sh', '/etc/service/tugboat/run'