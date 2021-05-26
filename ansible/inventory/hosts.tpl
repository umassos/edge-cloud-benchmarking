[master]
${master-public-ip}

[cpu_worker]
%{ for addr in cpu-worker-private-ip ~}
${addr}
%{ endfor ~}

[gpu-worker]
%{ for addr in gpu-worker-private-ip ~}
${addr}
%{ endfor ~}

[worker:children]
cpu-worker
gpu-worker

[load_generator]
${load-generator-public-ip}

[cluster:children]
master
worker

[worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'
