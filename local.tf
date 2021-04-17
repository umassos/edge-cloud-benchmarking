resource "local_file" "ansible-hosts" {
  content = templatefile("ansible/inventory/hosts.tpl",{
    master-public-ip = aws_instance.master.public_ip,
    worker-private-ip = aws_instance.workers.*.private_ip,
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

output "worker-ids" {
  value = aws_instance.workers.*.id
}

output "worker-private-ips" {
  value = aws_instance.workers.*.private_ip
}

output "load-generator-id" {
  value = aws_instance.load-generator.id
}

output "load-generator-ip" {
  value = aws_instance.load-generator.public_ip
}
