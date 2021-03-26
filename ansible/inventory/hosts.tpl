[master]
${master-public-ip}

[worker]
%{ for addr in worker-private-ip ~}
${addr}
%{ endfor ~}

[load-generator]
${load-generator-public-ip}

[all:children]
master
worker
load-generator

[worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'
master_ip=${master-private-ip}
