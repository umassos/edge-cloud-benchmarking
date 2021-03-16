[master]
${load-balancer-ip}

[workers]
%{ for addr in workers-internal-ip ~}
${addr}
%{ endfor ~}
