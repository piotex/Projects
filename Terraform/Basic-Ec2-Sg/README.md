


```
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

```
aws ec2 describe-instances \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress}" \
  --output table
```



```
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── security_group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2_instance/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf

```
