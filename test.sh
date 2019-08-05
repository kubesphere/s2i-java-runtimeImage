#!/bin/bash
set -ex

# ==================================================================================

function test_app() {
  local name=$1
  local port="8080"

  local container_id=$(docker run --name ${name}-test -d -p ${port} ${name})

  # sleep is required because after docker run returns, the container is up but our server may not quite be yet
  sleep 10

  local http_port="$(docker port ${container_id} ${port}|sed 's/0.0.0.0://')"
  local http_reply=$(curl --silent --show-error http://localhost:$http_port)

  if [ "$http_reply" = 'hello, world' ]; then
    echo "APP TEST PASSED"
    docker rm -f ${container_id}
    return 0
  else
    echo "APP TEST FAILED"
    docker logs ${container_id}
    docker rm -f ${container_id}
    return -123
  fi
}

# ==================================================================================

function test_entrypoint() {
  local name=$1
  local entrypoint=$2

  local container_id=$(docker run --name ${name}-test -d \
                         -e LANG=en_US.UTF-8 -e PARAMETER_THAT_MAY_NEED_ESCAPING="&'\"|< é\\(" ${name} \
                         ${entrypoint} --commandLineArgValueThatMayNeedEscaping="&'\"|< é\\(" --killDelay=1 --exitCode=0)

  # sleep is required because after docker run returns, the container is up but our server may not quite be yet
  local exitCode=$(docker wait ${container_id})

  if [ "$exitCode" = '0' ]; then
    echo "APP TEST PASSED (with entrypoint ${entrypoint})"
    docker rm -f ${container_id}
    return 0
  else
    echo "APP TEST FAILED (with entrypoint ${entrypoint})"
    docker logs ${container_id}
    docker rm -f ${container_id}
    return -123
  fi
}

# ==================================================================================

function test_container() {
  test_app $1
}

# ==================================================================================

function test_runtime_image() {
  local dir=$1
  local name=$2
  local builderImage=$3

  docker build ${dir} -t ${name}

  # ----------------------------------------------------------------------------------
  # Presence of any required tools
  #  * Issues #171 and #184: unzip is required for Spring Boot devtools support
  # ----------------------------------------------------------------------------------

  docker run --rm --name ${name}-test-unzip ${builderImage} unzip

  # --------------------------------------------------------------------------------
  # Gradle Spring Boot WAR  <https://github.com/fabric8io-images/s2i/issues/123>
  # --------------------------------------------------------------------------------

  s2i build --copy tmp/s2i-java-container/java/examples/spring-gradle ${builderImage} ${name}-spring-gradle --runtime-image ${name}

  test_container "${name}-spring-gradle"


  # ----------------------------------------------------------------------------------
  # Maven
  # ----------------------------------------------------------------------------------

  s2i build --copy tmp/s2i-java-container/java/examples/maven ${builderImage} ${name}-maven-example --runtime-image ${name}


  test_container "${name}-maven-example"


  # --------------------------------------------------------------------------------
  # Gradle
  # --------------------------------------------------------------------------------

  s2i build --copy tmp/s2i-java-container/java/examples/gradle ${builderImage} ${name}-gradle-example  --runtime-image ${name}

  # TODO https://github.com/fabric8io-images/s2i/issues/150
  # s2i build --copy java/examples/gradle ${name} ${name}-gradle-example --incremental

  test_container "${name}-gradle-example"


  # ----------------------------------------------------------------------------------
  # Binary
  # ----------------------------------------------------------------------------------

  mvn -f tmp/s2i-java-container/java/examples/maven/pom.xml clean package
  mkdir -p tmp/s2i-java-container/java/examples/binary/deployments/
  cp tmp/s2i-java-container/java/examples/maven/target/*.jar tmp/s2i-java-container/java/examples/binary/deployments/

  s2i build --copy tmp/s2i-java-container/java/examples/binary/ ${builderImage} ${name}-binary-example --runtime-image ${name}
  rm tmp/s2i-java-container/java/examples/binary/deployments/*

  test_container "${name}-binary-example"


  # ----------------------------------------------------------------------------------
  # Maven Wrapper
  # ----------------------------------------------------------------------------------

  s2i build --copy tmp/s2i-java-container/java/examples/maven-wrapper ${builderImage} ${name}-maven-wrapper-example --runtime-image ${name}


  # ----------------------------------------------------------------------------------
  # Entrypoint Binary
  # ----------------------------------------------------------------------------------
  if [ "$name" =  "s2i-java8-runtime" ]; then
    curl https://repo.spring.io/release/org/springframework/cloud/spring-cloud-deployer-spi-test-app/1.3.4.RELEASE/spring-cloud-deployer-spi-test-app-1.3.4.RELEASE-exec.jar \
         -o tmp/s2i-java-container/java/examples/binary/deployments/app.jar

    s2i build --copy tmp/s2i-java-container/java/examples/binary/ ${builderImage} ${name}-entrypoint-binary-example --runtime-image ${name}
    rm tmp/s2i-java-container/java/examples/binary/deployments/*

    test_entrypoint "${name}-entrypoint-binary-example" "java -jar /opt/run-java/deployments/app.jar"  # works
    test_entrypoint "${name}-entrypoint-binary-example" /opt/run-java/run-java.sh         # will fail until https://github.com/fabric8io-images/run-java-sh/issues/75 is fixed
    test_entrypoint "${name}-entrypoint-binary-example" /usr/local/s2i/run                # will fail until https://github.com/fabric8io-images/run-java-sh/issues/75 is fixed
  fi
}

# ==================================================================================

function test_tomcat_java8_image() {
  local dir="tomcat85-java8"
  local name="tomcat85-java8-runtime"

  docker build ${dir} -t ${name}

  s2i build --copy tmp/s2i-java-container/tomcat/examples/spring-mvc-showcase kubespheredev/tomcat85-java8-centos7 ${name}-spring-mvc --runtime-image ${name}

  local port="8080"

  local container_id=$(docker run --name ${name}-spring-mvc-test -d -p ${port} ${name}-spring-mvc)

  # sleep is required because after docker run returns, the container is up but our server may not quite be yet
  sleep 10
  local http_port="$(docker port ${container_id} ${port}|sed 's/0.0.0.0://')"
  local http_reply=$(curl --silent --show-error http://localhost:$http_port/spring-mvc-showcase/simple)
  echo $http_reply
  if [ "$http_reply" =  "Hello world!" ]; then
    echo "APP TEST PASSED"
    docker rm -f ${container_id}
    return 0
  else
    echo "APP TEST FAILED"
    docker logs ${container_id}
    docker rm -f ${container_id}
    return -123
  fi
}

function test_tomcat_java11_image() {
  local dir="tomcat85-java11"
  local name="tomcat85-java11-runtime"

  docker build ${dir} -t ${name}

  s2i build --copy tmp/s2i-java-container/tomcat/examples/springmvc5 kubespheredev/tomcat85-java11-centos7 ${name}-spring-mvc-5 --runtime-image ${name}

  local port="8080"

  local container_id=$(docker run --name ${name}-spring-mvc-5-test -d -p ${port} ${name}-spring-mvc-5)

  # sleep is required because after docker run returns, the container is up but our server may not quite be yet
  sleep 10
  local http_port="$(docker port ${container_id} ${port}|sed 's/0.0.0.0://')"
  local http_reply=$(curl --silent --show-error http://localhost:$http_port/spring-mvc-java11/hello)
  echo $http_reply
  if [ "$http_reply" =  "Hello world!" ]; then
    echo "APP TEST PASSED"
    docker rm -f ${container_id}
    return 0
  else
    echo "APP TEST FAILED"
    docker logs ${container_id}
    docker rm -f ${container_id}
    return -123
  fi
}

# ==================================================================================

mkdir tmp && cd tmp && git clone https://github.com/kubesphere/s2i-java-container 

test_runtime_image "java8" "s2i-java8-runtime" "kubespheredev/java-8-centos7"
test_runtime_image "java11" "s2i-java11-runtime" "kubespheredev/java-11-centos7"


test_tomcat_java8_image
test_tomcat_java11_image

rm -rf tmp
