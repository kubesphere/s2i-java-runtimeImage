pipeline {
  agent {
    node {
      label 'base'
    }

  }
  stages {
    stage('build and tag image') {
      steps {
        container('base') {
          sh '''docker build -t kubespheredev/s2i-java8-runtime .
docker tag kubespheredev/s2i-java8-runtime kubespheredev/s2i-java8-runtime:advanced-2.1.0-dev'''
        }

      }
    }
    stage('docker push') {
      when{
        branch 'master'
      }
      steps {
        container('base') {
          withCredentials([usernamePassword(passwordVariable : 'DOCKER_PASSWORD' ,usernameVariable : 'DOCKER_USERNAME' ,credentialsId : 'dockerhub-id' ,)]) {
            sh 'echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin'

          }
            sh 'docker push kubespheredev/s2i-java8-runtime'
        }
      }
    }
  }
}
