pipeline {

  options {
    disableConcurrentBuilds()
    timeout(time: 1, unit: 'HOURS')
    ansiColor('xterm')
  }

  parameters {
    choice (name: 'action', choices: 'create\ndestroy', description: 'Create or destroy the region vpn.')
    string (name: 'region', defaultValue : 'eu-west-2', description: 'AWS region to create/destroy vpn.')
    string(name: 'credential', defaultValue : 'jenkins', description: "Jenkins credential that provides the AWS access key and secret.")
  }

  agent { label 'master' }

  tools {
    terraform '1.0'
  }

  stages {
    stage('Setup') {
      steps {
        script {
          cluster = params.cluster
          currentBuild.displayName = '#' + env.BUILD_NUMBER + ' ' + params.action + ' vpn ' + params.region
       }
      }
    }

    stage('Deploy') {
      when {
          expression { params.action == 'create' }
      }
      steps {
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
          credentialsId: params.credential, 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',  
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            sh """
              terraform init
              AWS_REGION=${params.region} ./apply-generate-ovpn.sh display-ovpn
            """
          }
        }
      }
    }

    stage('Destroy') {
      when {
          expression { params.action == 'destroy' }
      }
      steps {
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
          credentialsId: params.credential, 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',  
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            sh "AWS_REGION=${params.region} terraform workspace select ${params.region} && terraform destroy -auto-approve"
          }
        }
      }
    }
  }
}
