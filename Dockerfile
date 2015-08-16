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
RUN chmod -R go+rw $JBOSS_HOME && \
    chmod -R go+rw /opt/s2i/destination

RUN chown -R 1001:1001 /dependency-loader

# This default user is created in the openshift/base-centos7 image
USER 1001

# Make fake project to load dependencies
RUN mkdir -p $HOME/.m2/repository && \
    curl -o $HOME/.m2/repository/settings.xml https://raw.githubusercontent.com/jboss-switchyard/quickstarts/2.0.0.Final/settings.xml && \
    mkdir -p $HOME/.m2/repository/org/jboss/bom/eap6-supported-artifacts/6.3.0.GA && \
    curl -o $HOME/.m2/repository/org/jboss/bom/eap6-supported-artifacts/6.3.0.GA/eap6-supported-artifacts-6.3.0.GA.pom https://maven.repository.redhat.com/techpreview/all/org/jboss/bom/eap6-supported-artifacts/6.3.0.GA/eap6-supported-artifacts-6.3.0.GA.pom && \
    mkdir -p $HOME/.m2/repository/org/jboss/jboss-parent/11-redhat-1 && \
    curl -o $HOME/.m2/repository/org/jboss/jboss-parent/11-redhat-1/jboss-parent-11-redhat-1.pom http://maven.repository.redhat.com/techpreview/all/org/jboss/jboss-parent/11-redhat-1/jboss-parent-11-redhat-1.pom && \
    mkdir -p $HOME/.m2/repository/org/jboss/as/jboss-as-parent/7.4.0.Final-redhat-19 && \
    curl -o $HOME/.m2/repository/org/jboss/as/jboss-as-parent/7.4.0.Final-redhat-19/jboss-as-parent-7.4.0.Final-redhat-19.pom https://maven.repository.redhat.com/techpreview/all/org/jboss/as/jboss-as-parent/7.4.0.Final-redhat-19/jboss-as-parent-7.4.0.Final-redhat-19.pom && \
    cd /dependency-loader && mvn clean package && cd $HOME && rm -rf /dependency-loader/*

# Set the default port for applications built using this image
EXPOSE 8080

CMD ["usage"]
