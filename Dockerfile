# sti-switchyard
FROM openshift/base-centos7

# Put the maintainer name in the image metadata
MAINTAINER Alexander Sokolovsky <amsokol@gmail.com>

# Rename the builder environment variable to inform users about application you provide them
ENV SWITCHYARD_VERSION 1.0

# Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building and running SwitchYard applications" \
      io.k8s.display-name="SwitchYard 2.0" \
      io.openshift.tags="builder,switchyard,switchyard20"
      io.openshift.expose-services="8080:http" \

# Install required packages here:
RUN yum install -y git golang mc && yum clean all -y

# TODO (optional): Copy the builder files into /opt/openshift
# COPY ./<builder_folder>/ /opt/openshift/

# Copy the S2I scripts to /usr/local/sti, since openshift/base-centos7 image sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./.sti/bin/ /usr/local/sti

# Drop the root user and make the content of /opt/openshift owned by user 1001
RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

ENV GOPATH /opt/app-root

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["usage"]
