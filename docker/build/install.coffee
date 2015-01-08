require 'shelljs/global'

# Link node
ln '-s', '/usr/bin/nodejs', '/usr/bin/node'

# Disable ssh
rm '-rf', '/etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh'

# Install consul
cp '-R', 'consul', '/consul'
mkdir '/etc/service/consul'
cp 'consul/run.sh', '/etc/service/consul/run'
cp 'consul/bin/consul', '/usr/local/bin/consul'
'2'.to '/etc/container_environment/GOMAXPROCS'

# Install tugboat-consul
exec 'npm install -g tugboat-consul tugboat ducke'
cp '-R', 'tugboat', '/tugboat'
mkdir '/etc/service/tugboat'
cp 'tugboat/run.sh', '/etc/service/tugboat/run'