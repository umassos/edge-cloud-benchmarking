# #!/usr/bin/env bash
set -e

# us-east-2a to us-east-2c, 1 server
terraform apply -var load-generator-region=us-east-2 \
                -var cluster-region=us-east-2 \
                -var cluster-availability-zone=c \
                -var cpu-worker-count=1 \
                -var gpu-worker-count=1 -auto-approve

(cd ansible && ansible-playbook ping.yml && ansible-playbook setup.yml && ansible-playbook experiment.yml)

terraform destroy -var load-generator-region=us-east-2 \
                -var cluster-region=us-east-2 \
                -var cluster-availability-zone=c \
                -var cpu-worker-count=1 \
                -var gpu-worker-count=1 -auto-approve

# us-east-2a to ca-central-1a, 10 servers
terraform apply -var load-generator-region=us-east-2 \
                -var cluster-region=ca-central-1 \
                -var cpu-worker-count=5 \
                -var gpu-worker-count=5 -auto-approve

(cd ansible && ansible-playbook ping.yml && ansible-playbook setup.yml && ansible-playbook experiment.yml)

terraform destroy -var load-generator-region=us-east-2 \
                -var cluster-region=ca-central-1 \
                -var cpu-worker-count=5 \
                -var gpu-worker-count=5 -auto-approve
