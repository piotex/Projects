# Create Basic S3

### Use profile-1 as default profile (to don't repet using --profile flag)
```
export AWS_PROFILE=profile-1
aws s3 ls
```

### Deploy Infra using Terraform
```
terraform init
terraform plan
terraform apply
```

### Destroy resources
```
terraform destroy
```