pipeline {
  agent {
    node {
      label 'maven'

  }
  stages {
    stage('build and tag image') {
      steps {
        container('maven') {
          sh './test.sh'
        }

      }
    }
     stage('docker tag') {
          when{
            branch 'master'
          }
          steps {
            container('maven') {
                sh '''docker tag s2i-java8-runtime kubespheredev/java-8-runtime
                docker tag s2i-java11-runtime kubespheredev/java-11-runtime
                docker tag tomcat85-java8-runtime kubespheredev/tomcat85-java8-runtime
                docker tag tomcat85-java11-runtime kubespheredev/tomcat85-java11-runtime
                '''
            }
          }
     }
    stage('docker push') {
      when{
        branch 'master'
      }
      steps {
        container('maven') {
                sh '''docker push kubespheredev/java-8-runtime
                docker push kubespheredev/java-11-runtime
                docker push kubespheredev/tomcat85-java8-runtime
                docker push kubespheredev/tomcat85-java11-runtime
                '''
        }
      }
    }
  }
}
