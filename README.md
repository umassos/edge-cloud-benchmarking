# Performance Benchmarking Framework for Edge/Cloud Environments

This branch contains the scripts used to run the experiments with a heterogeneous cluster, i.e.,
some of the VMs in the cluster are CPU instances while the others are GPU instances.

## Prerequisites

1. [Terraform](https://www.terraform.io/)

2. [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

3.  Provide AWS credentials If you use plan to run the benchmarks on AWS you need to provide your
    AWS credentials so that Terraform can provision the needed resources on your behalf. The easiest
    way is to provide your credentials via the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
    environment variables:

    ```shell
    export AWS_ACCESS_KEY_ID="your_access_key"
    export AWS_SECRET_ACCESS_KEY="your_secret_key"
    ```

    For more information, refer to the [Terraform AWS Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)

4.  Generate a key pair, This key pair's public key will be registered with AWS to allow logging-in
    to EC2 instances.

    ```shell
    ssh-keygen -t rsa -m PEM
    ```

    After the key pair is created, copy the public key to the root folder of this project and rename
    it `edge-modeling.pub`.

5.  Start the ssh-agent in the background and add your generated private key. This is required for
    terraform to set up the EC2 servers over ssh.
    ```shell
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/edge-modeling.pem
    ```
## Usage
You can refer to and modify [run.sh](run.sh) to get started quickly. You can also manually run the
benchmarks following the following steps below:

1.  Provision the resources using `terraform apply`. You can specify the number and instance type of
    CPU instances as well as GPU instances using the following variables:
    * `cpu-worker-count`: controls how many CPU instances are in the cluster.
    * `cpu-worker-instance-type`: controls which instance type is used for CPU instances (default is
      `c5a.xlarge`).
    * `gpu-worker-count`: controls how many GPU instances are in the cluster.
    * `gpu-worker-instance-type`: controls which instance type is used for GPU instances (default is
      `g4dn.xlarge`).

    Example:
    ```shell
    terraform apply -var load-generator-region=us-east-2 \
                    -var cluster-region=us-east-2 \
                    -var cluster-availability-zone=c \
                    -var cpu-worker-count=1 \
                    -var gpu-worker-count=1
    ```

    You can use the variables to specify the region/availability zone of both the load generator and
    the cluster. You can also adjust the number of worker nodes in the cluster using the
    `worker_count` variable.

2.  Run the benchmarks.

    ```
    (cd ansible && ansible-playbook ping.yml && ansible-playbook setup.yml && ansible-playbook experiment.yml)
    ```

3.  Tear down the resources.

    ```
    terraform destroy -var load-generator-region=us-east-2 \
                -var cluster-region=us-east-2 \
                -var cluster-availability-zone=c \
                -var cpu-worker-count=1 \
                -var gpu-worker-count=1
    ```

    __[Important!]__ The variables in your `terraform destroy` command need to be the same as what
    you used in the `terraform apply` command. Otherwise your provision may end up in an invalid
    state (e.g., Terraform thinks your instances has been terminated, while they are actually still
    running in another region) and you may end up with surprise charges from AWS.
