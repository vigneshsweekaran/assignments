## Multi tiered web application in AWS using terraform

Creates vpc, Load balancer, autoscaling group, RDS, elasticache and ec2 instance with apache.

### Terraform plan
terraform plan \
    -var=rds_password="password#123"

### Terraform apply
terraform apply \
    -var=rds_password="password#123"

### Terraform destroy
terraform destroy \
    -var=rds_password="password#123"
