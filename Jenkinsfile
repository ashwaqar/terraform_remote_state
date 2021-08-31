pipeline {
    options {
        buildDiscarder(logRotator(
            numToKeepStr: '15',
            daysToKeepStr: '30'
        ))
        disableConcurrentBuilds()
    }

    agent {
        node {
            label 'master'
            customWorkspace "${JENKINS_HOME}/workspace/${JOB_NAME}/${BUILD_NUMBER}"
        }
    }

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
        stage ("Migrate state to S3 backend") {
            when {
                expression {
                    params.BOOTSTRAP == true
                }
            }
            steps {
                replaceTextInFile('backend.tf', 'local', 's3')
                sh """
                    terraform init \
                        -input=false \
                        -backend-config=environments/${params.TARGET_ENVIRONMENT}/remote-backend.properties \
                        -migrate-state \
                        -force-copy
                """
            }
        }
        stage("Init-Validate-Plan-Apply against S3 backend") {
            steps {
                script {
                    replaceTextInFile('backend.tf', 'local', 's3')
                    sh """
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

void replaceTextInFile(String filepath, String sourceText, String newText) {
    def oldContent = readFile(file: filepath)
    def newContent = oldContent.replaceAll(sourceText, newText)
    writeFile(file: filepath, text: newContent)
}