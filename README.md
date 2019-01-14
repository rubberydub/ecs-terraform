
# ECS Terraform

An example Terraform project to deploy an EC2 backed ECS cluster.

## TODO

- ECS Cluster:
  - Add SSH bastion.
  - Add NAT gateway.
- Kong ECS service example:
  - Switch to awsvpc network mode and clean up ingress.
  - Serve something with Kong.
  - Add a volume for the Postgres data.
  - Add Kong dashboard.
  - DNS entry with route53.
  - SSL.
  - Statuscake test.

## Usage

Copy the example private variables file and edit it accordingly:
```shell
cp example-private.tfvars private.tfvars
$EDITOR private.tfvars
```
The private variables file contains values that should not be committed to
git, such as AWS keys.  

Copy the example variables file and edit it accordingly:
```shell
cp example.tfvars mycluster.tfvars
$EDITOR mycluster.tfvars
```

Run Terraform:
```shell
terraform init
terraform plan -var-file=private.tfvars -var-file=mycluster.tfvars -var-file=myservices.tfvars
terraform apply -var-file=private.tfvars -var-file=mycluster.tfvars -var-file=myservices.tfvars
```

Output SSH config:
```shell
terraform output ssh-config
```
