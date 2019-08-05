pipeline {
  agent {
    node {
      label 'maven'
      }
  }
  stages {
    stage('build and tag image') {
      steps {
        container('maven') {
          sh '''wget -O s2i.tar.gz https://github.com/openshift/source-to-image/releases/download/v1.1.13/source-to-image-v1.1.13-b54d75d3-linux-amd64.tar.gz
          tar -xvf s2i.tar.gz
          cp ./s2i /usr/local/bin'''
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
