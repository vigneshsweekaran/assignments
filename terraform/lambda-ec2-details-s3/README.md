## AWS Lambda function using python to fetch the aws ec2 instance details

* Fetch ec2 instances running in a particular AWS account using lambda function - python
* Trigger this lambda function twice a day
* Get the name, instance class, machine image and tags for all EC2 instances in the environment
with a "Running" state
* Alert on all instances running without tag key "Service", or with a tag value that doesn't match
one of ["Data", "Processing", "Web"]
* Write a CSV representation of the inventory to a new S3 object
* If the function is invoked with the parameter {"Test" : "True"}, no alerts are sent

### Terraform plan
terraform plan

### Terraform apply
terraform apply

### Terraform destroy
terraform destroy