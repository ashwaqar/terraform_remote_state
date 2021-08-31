this bootstrap phase is performed only once to configure remote-state backend

setup the AWS session using CLI
```
$saml2aws login -a lunar2-non-production-admin
```
export the environment variables
```
export AWS_PROFILE=lunar2-non-production-admin AWS_DEFAULT_REGION=us-west-2  AWS_SDK_LOAD_CONFIG=1
```
run locally from a developer’s workstation on the first execution. This provisions the cloud resources terraform requires for remote state management
```
terraform init
terraform validate
terraform plan -out tfplan.out
terraform apply tfplan.out
```
Second step is to configure the TF state to point to the newly created remote backend
Replace `backend "local" {}` with `backend "s3" {}` in the `backend.tf` file
below example targets the dev environment
```
terraform init -backend-config=environments/dev/remote-backend.properties -reconfigure
terraform validate
terraform plan -out tfplan.out
terraform apply tfplan.out
```

Known Issues

life cycle destroy for S3 cannot be controlled through an input parameter since the lifecycle block does not allow variables.
Change the value to true/false in main.tf when you have to delete the S3 buckets