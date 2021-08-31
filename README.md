## Following instructions are for local setup. Jenkinsfile automates this process

__setup the AWS session using CLI__
```
$saml2aws login -a lunar2-non-production-admin
```
__export the environment variables__
```
$export AWS_PROFILE=lunar2-non-production-admin AWS_DEFAULT_REGION=us-west-2  AWS_SDK_LOAD_CONFIG=1
```
__bootstrap phase is performed only once to configure remote-state backend. This provisions the cloud resources terraform requires for remote state management__
```
$terraform init
$terraform validate
$terraform plan -out tfplan.out
$terraform apply tfplan.out
```
__Second step is to configure the TF state to point to the newly created remote backend. Replace `backend "local" {}` with `backend "s3" {}` in the `backend.tf` file. Below example targets the dev environment__
```
$terraform init -backend-config=environments/dev/remote-backend.properties -reconfigure
$terraform validate
$terraform plan -out tfplan.out
$terraform apply tfplan.out
```

### Known Issues

To prevent accidental deletions of S3 buckets, `prevent_destroy` flag is set to `true`
If you intend to delete the S3 buckets, change the value to `false` in `main.tf` manually
*life cycle destroy for S3 cannot be controlled through an input parameter since the lifecycle block does not allow variables*