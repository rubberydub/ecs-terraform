
# ECS Terraform

An example Terraform project to deploy an EC2 backed ECS cluster.

## TODO

- Add ELB for SSH.
- Example service.
- Statuscake test for example service.
- Cloudwatch?

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
terraform plan -var-file=private.tfvars -var-file=mycluster.tfvars
terraform apply -var-file=private.tfvars -var-file=mycluster.tfvars
```
