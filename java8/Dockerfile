FROM openjdk:8-alpine

ARG EXPOSE_PORT=8080
EXPOSE ${EXPOSE_PORT}

ENV PATH=$PATH:"/usr/local/s2i"

# Some version information
LABEL io.k8s.description="Platform for running plain Java applications (fat-jar and flat classpath)" \
      io.k8s.display-name="Java Applications" \
      io.kubesphere.tags="runtime,java" \
      io.kubesphere.s2i.scripts-url="image:///usr/local/s2i" \
      io.kubespehre.s2i.destination="/tmp" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      io.openshift.s2i.destination="/tmp" \
      io.openshift.s2i.assemble-input-files="/deployments" \
      com.yunify.deployments-dir="/deployments" \
      com.yunify.dev-mode="JAVA_DEBUG:false" \
      com.yunify.dev-mode.port="JAVA_DEBUG_PORT:5005"

# S2I scripts + README
COPY s2i /usr/local/s2i
RUN chmod 755 /usr/local/s2i/*

# Add run script as /opt/run-java/run-java.sh and make it executable
COPY run-java /opt/run-java/
RUN chmod 755 /opt/run-java/*

WORKDIR /usr/local/s2i

# Use the run script as default since we are working as an hybrid image which can be
# used directly to. (If we were a plain s2i image we would print the usage info here)
CMD [ "/usr/local/s2i/run" ]
