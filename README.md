
# ECS Terraform

An example Terraform project to deploy an EC2 backed ECS cluster.

## TODO

- Kong example:
  - Add an ELB to expose Kong.
  - Serve something with Kong.
  - Add a volume for the Postgres data.
- Add a DNS entry with route53.
- Statuscake test for example service.
- Add SSH bastion.
- Add NAT gateway.

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
