pipeline {
  options {
    buildDiscarder(logRotator(
        numToKeepStr: '15',
        daysToKeepStr: '30'
    ))
    disableConcurrentBuilds()
  }

  agent any

  parameters{
    choice(
        name: 'TARGET_ENVIRONMENT',
        choices: ['sandbox','dev','sqa','val','staging','prod'],
        description: 'Infra deployment environment'
    )
    booleanParam(
        name: 'BOOTSTRAP',
        defaultValue: false,
        description: 'Are you creating remote S3 and DynamoDB backend first time'
    )
    booleanParam(
        name: 'APPLY',
        defaultValue: false,
        description: 'The infra will be applied to the chosen environment.'
    )
    booleanParam(
        name: 'DESTROY',
        defaultValue: false,
        description: 'The infra will be destroyed in the chosen environment.'
    )
  }

  environment {
    TF_AWS_ACCOUNT          = 'lunar2-non-production'
    AWS_ACCESS_KEY_ID       = credentials("${env.TF_AWS_ACCOUNT}_TERRAFORM_ACCESS_KEY")
    AWS_SECRET_ACCESS_KEY   = credentials("${env.TF_AWS_ACCOUNT}_TERRAFORM_SECRET_KEY")
    TF_DIR                  = './'
    SEND_SLACK_NOTIFICATION = false
  }

  stages {
    stage("Init-Validate-Plan-Apply against local backend"){
        when {
            expression {
                params.BOOTSTRAP == true 
            }
        }
        steps {
            script {
                sh """
                    terraform init -input=false
                    terraform validate
                    terraform plan \
                        -out=${params.TARGET_ENVIRONMENT}_tfplan \
                        -var 'env=${params.TARGET_ENVIRONMENT}'
                    terraform apply ${params.TARGET_ENVIRONMENT}_tfplan
                """
            }
        }
    }
    stage ("Init reconfigure against S3 backend") {
        when {
            expression {
                params.BOOTSTRAP == true 
            }
        }
        steps {
            sh """
                replaceTextInFile('backend.tf', 'local', 's3')
                terraform init \
                    -input=false \
                    -backend-config=environments/${params.TARGET_ENVIRONMENT}/remote-backend.properties \
                    -reconfigure
            """
        }
    }
    stage("Init-Validate-Plan-Apply against S3 backend"){
        stages {
            stage("Init-Validate-Plan-Apply") {
                steps {
                    script {
                        sh """
                            replaceTextInFile('backend.tf', 'local', 's3')
                            terraform init \
                                -input=false \
                                -backend-config=environments/${params.TARGET_ENVIRONMENT}/remote-backend.properties
                            terraform validate
                            terraform plan \
                                -out=${params.TARGET_ENVIRONMENT}_tfplan \
                                -var 'env=${params.TARGET_ENVIRONMENT}'
                        """
                        if (params.APPLY) {
                            sh "terraform apply ${params.TARGET_ENVIRONMENT}_tfplan"
                        }
                    }
                }
            }
            stage("Terraform destroy") {
                when {
                    expression {
                        (params.DESTROY == true)
                    }
                }
                steps {
                    sh "terraform destroy -var 'env=${params.TARGET_ENVIRONMENT}' -auto-approve"
                }
            }

        }
    }
  }
}

void replaceTextInFile(String filepath, String sourceText, String newText) {
    def text = readFile filepath
    text.replaceAll(sourceText, newText)
}