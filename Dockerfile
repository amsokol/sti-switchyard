# sti-switchyard
FROM openshift/base-centos7

# Put the maintainer name in the image metadata
MAINTAINER Alexander Sokolovsky <amsokol@gmail.com>

# Rename the builder environment variable to inform users about application you provide them
ENV SWITCHYARD_VERSION 2.0.0.Final

# Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building and running SwitchYard applications" \
      io.k8s.display-name="SwitchYard 2.0" \
      io.openshift.tags="builder,switchyard,switchyard20" \
      io.openshift.expose-services="8080:http" \
      io.openshift.s2i.destination="/opt/s2i/destination"

# Install Maven, Wildfly 8
RUN yum install -y --enablerepo=centosplus \
    tar unzip bc which lsof bsdtar java-1.7.0-openjdk java-1.7.0-openjdk-devel mc && \
    yum clean all -y && \
    (curl -0 http://mirror.sdunix.com/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-3.3.3/bin/mvn /usr/local/bin/mvn && \
    mkdir -p /wildfly && \
    (curl -0 http://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz | tar -zx --strip-components=1 -C /wildfly) && \
    mkdir -p /opt/app-root/source && \
    mkdir -p /opt/s2i/destination
ENV JBOSS_HOME /wildfly

# Install SwitchYard 2.0
RUN (curl -L http://downloads.jboss.org/switchyard/releases/v2.0.Final/switchyard-$SWITCHYARD_VERSION-WildFly.zip | bsdtar -C $JBOSS_HOME -xvf-)
ADD ./contrib/ /

# Copy the STI scripts from the specific language image to /usr/local/sti
COPY ./.sti/bin/ /usr/local/sti

# Create wildfly group and user, set file ownership to that user.
RUN chmod -R go+rw /wildfly && \
    chmod -R go+rw /opt/s2i/destination

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

CMD ["usage"]
