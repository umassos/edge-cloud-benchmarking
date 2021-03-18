[master]
${master-public-ip}

[worker]
%{ for addr in worker-private-ip ~}
${addr}
%{ endfor ~}

[k3s:children]
master
worker

[worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'
master_ip=${master-private-ip}
