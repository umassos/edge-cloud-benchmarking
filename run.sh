# #!/usr/bin/env bash
set -e

# us-east-2a to us-east-2c
terraform apply -var load-generator-region=us-east-2 \
                -var cluster-region=us-east-2 \
                -var cluster-availability-zone=c
                -var worker-count=1 -auto-approve

(cd ansible && ansible-playbook ping.yml && ansible-playbook setup.yml && ansible-playbook experiment.yml)

terraform destroy -var load-generator-region=us-east-2 \
                -var cluster-region=us-east-2 \
                -var cluster-availability-zone=c
                -var worker-count=1 -auto-approve

# us-east-2 to ca-central-1
terraform apply -var load-generator-region=eu-east-2 \
                -var cluster-region=ca-central-1 \
                -var worker-count=10 -auto-approve

(cd ansible && ansible-playbook ping.yml && ansible-playbook setup.yml && ansible-playbook experiment.yml)

terraform apply -var load-generator-region=eu-east-2 \
                -var cluster-region=ca-central-1 \
                -var worker-count=10 -auto-approve
