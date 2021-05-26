resource "local_file" "ansible-hosts" {
  content = templatefile("ansible/inventory/hosts.tpl",{
    master-public-ip = aws_instance.master.public_ip,
    cpu-worker-private-ip = aws_instance.cpu-workers.*.private_ip,
    gpu-worker-private-ip = aws_instance.gpu-workers.*.private_ip,
    load-generator-public-ip = aws_instance.load-generator.public_ip
  })
  filename = "ansible/inventory/hosts.ini"
  file_permission = "0644"
}

output "master-id" {
  value = aws_instance.master.id
}

output "master-ip" {
  value = aws_instance.master.public_ip
}

output "cpu-worker-ids" {
  value = aws_instance.cpu-workers.*.id
}

output "cpu-worker-private-ips" {
  value = aws_instance.cpu-workers.*.private_ip
}

output "gpu-worker-ids" {
  value = aws_instance.gpu-workers.*.id
}

output "gpu-worker-private-ips" {
  value = aws_instance.gpu-workers.*.private_ip
}

output "load-generator-id" {
  value = aws_instance.load-generator.id
}

output "load-generator-ip" {
  value = aws_instance.load-generator.public_ip
}
