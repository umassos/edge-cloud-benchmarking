[master]
${master-public-ip}

[worker]
%{ for addr in worker-private-ip ~}
${addr}
%{ endfor ~}

[load_generator]
${load-generator-public-ip}

[cluster:children]
master
worker

[worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'
