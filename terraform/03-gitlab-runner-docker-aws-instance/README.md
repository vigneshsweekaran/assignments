## Terraform to create aws ec2 instance and ansible to install the Gitlab-runner and registering it

* Terraform scripts are used to create the aws EC2 instance
* Ansible playbook is used to install and register the gitlab runner

### Installation steps
* Update the values in terraform.tfvars file

* Configure the aws credentials in profile test

* Make sure ssh keys are generated in ~/.ssh, which is used for craeting key_pair and connecting to aws instance for running the ansible playbook

* To generate ssh keys
```
ssh-keygen
```

* Run the following terrform commands to initialize, create the resources and register the gitlab runner
```
terraform init
terraform plan \
  -var=runner_token="xxxxxxxxxxx"
terraform apply --auto-approve \
  -var=runner_token="xxxxxxxxxxx"

where xxxxxxxx = Gitlab runner registration token
```

* To destroy the created resources
```
terraform destroy --auto-approve \
  -var=runner_token="xxxxxxxxxxx"
```
