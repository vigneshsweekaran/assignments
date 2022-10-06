## Terraform script to deploy a gitlab runner on Kubernetes cluster with k8s runner type

![Architecture](/terraform/04-gitlab-runner-k8s/gitlab-runner.png)

### Command Usage with local state file
##### Terraform Init
```
terraform init
```

##### Terraform Validate
```
terraform validate
```

##### Terraform Plan
```
terraform plan \
  -var="runner_token=xxxxxxxxxxxx"
```

##### Terraform Apply
```
terraform apply \
  -var="runner_token=xxxxxxxxxxxx"
```

##### Terraform Destroy
```
terraform destroy \
  -var="runner_token=xxxxxxxxxxxx"
```

### Pipeline run
https://gitlab.com/vigneshsweekaran/hello-world/-/pipelines/660318491

### Screenshots

Gitlab runner configured

![Gitlab runner configured](/terraform/03-gitlab-runner-docker-aws-instance/gitlab-runner-k8s.PNG)
