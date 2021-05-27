[master]
${master-public-ip}

[cpu_worker]
%{ for addr in cpu-worker-private-ip ~}
${addr}
%{ endfor ~}

[gpu_worker]
%{ for addr in gpu-worker-private-ip ~}
${addr}
%{ endfor ~}

[load_generator]
${load-generator-public-ip}

[worker:children]
cpu_worker
gpu_worker

[cluster:children]
master
worker

[cpu_worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'

[gpu_worker:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ubuntu@${master-public-ip}"'
