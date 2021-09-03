pipeline {

  options {
    disableConcurrentBuilds()
    timeout(time: 1, unit: 'HOURS')
    ansiColor('xterm')
  }

  parameters {
    choice (name: 'action', choices: 'create\ndestroy', description: 'Create or destroy the region vpn.')
    string (name: 'region', defaultValue : 'eu-west-2', description: 'AWS region to create/destroy vpn.')
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
          currentBuild.displayName = '#' + env.BUILD_NUMBER + ' ' + params.action + params.region
       }
      }
    }

    stage('Deploy') {
      when {
          expression { params.action == 'create' }
      }
      steps {
        script {
          sh "AWS_REGION=${params.region} ./apply-generate-ovpn.sh display-ovpn"

        }
      }
    }

    stage('Destroy') {
      when {
          expression { params.action == 'destroy' }
      }
      steps {
        script {
          sh """
            export AWS_REGION=${params.region}
            terraform workspace select $AWS_REGION && terraform destroy -auto-approve
        }
      }
    }
  }
}
