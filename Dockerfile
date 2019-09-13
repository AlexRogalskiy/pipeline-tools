FROM docker:17.09.1-ce as docker
# Build operator-sdk
FROM stakater/go-dep:1.9.3 as operator-sdk-builder
RUN mkdir -p $GOPATH/src/github.com/operator-framework && \
    cd $GOPATH/src/github.com/operator-framework && \
    git clone https://github.com/operator-framework/operator-sdk && \
    cd operator-sdk && \
    git checkout tags/v0.2.1 && \
    make dep && \
    make install
FROM stakater/base-centos:7
LABEL name="Pipeline Tools" \
      maintainer="Stakater <stakater@aurorasolutions.io>" \
      vendor="Stakater" \
      summary="A docker image containing tools required for pipelines"
# Change to user root to
USER root
COPY --from=operator-sdk-builder /go/bin/operator-sdk /usr/local/bin
COPY --from=docker /usr/local/bin/docker /usr/local/bin/
# Update repository list in separate layer
# so that install layer does not run everytime
RUN yum update -y
# This is needed for compatibility with our nodes
ENV DOCKER_API_VERSION=1.32
# Install utilities from yum
RUN echo "===> Installing Utilities from yum ..."  && \
    yum install -y epel-release && \
    yum install -y sudo git wget openssh groff less python python-pip jq unzip gcc-c++ make openssl \
                  sshpass openssh-clients rsync gnupg gettext which java-1.8.0-openjdk-1.8.0.191.b12 && \
    \
    echo "===> Cleaning YUM cache..."  && \
    yum clean all
RUN echo "===> Installing Tools via pip ..." && \
    pip install --upgrade pip cffi && \ 
    pip install --upgrade ansible boto3 awscli git+https://github.com/makethunder/awsudo.git pywinrm && \
    \
    echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts
# Install nodejs
RUN curl -sL https://rpm.nodesource.com/setup_8.x | sudo bash - && \
    yum install -y nodejs-8.12.0
# Install golang
ARG GO_VERSION=1.11.4
ARG GO_URL=https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
RUN mkdir -p /tmp/go/ && \
    wget ${GO_URL} -O /tmp/go/go.tar.gz && \
    tar -xzvf /tmp/go/go.tar.gz -C /tmp/go/ && \
    mv /tmp/go/go /usr/local/go && \
    rm -rf /tmp/* && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    mkdir -p /go/ /go/bin
ENV GOROOT /usr/local/go
ENV GOPATH /go 
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
# Install gotpl
ARG GOTPL_VERSION=0.1.5
ARG GOTPL_URL=https://github.com/wodby/gotpl/releases/download/${GOTPL_VERSION}/gotpl-linux-amd64-${GOTPL_VERSION}.tar.gz
RUN mkdir -p /tmp/gotpl/ && \
    wget ${GOTPL_URL} -O /tmp/gotpl/gotpl.tar.gz && \
    tar -xzvf /tmp/gotpl/gotpl.tar.gz -C /tmp/gotpl/ && \
    mv /tmp/gotpl/gotpl /usr/local/bin/gotplenv
# Install kops, kubectl, and terraform
RUN mkdir -p /aws && \
    curl -LO --show-error https://github.com/kubernetes/kops/releases/download/1.12.1/kops-linux-amd64 && \
    mv kops-linux-amd64 /usr/local/bin/kops && \
    chmod +x /usr/local/bin/kops && \
    curl -LO --show-error https://storage.googleapis.com/kubernetes-release/release/v1.12.1/bin/linux/amd64/kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip && \
    unzip terraform_0.11.11_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_0.11.11_linux_amd64.zip
# Install helm, and landscaper
ARG HELM_VERSION=v2.11.0
ARG HELM_FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz
ARG HELM_URL=http://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME}
ARG LANDSCAPER_VERSION=1.0.12
ARG LANDSCAPER_FILENAME=landscaper-${LANDSCAPER_VERSION}-linux-amd64.tar.gz
ARG LANDSCAPER_URL=https://github.com/Eneco/landscaper/releases/download/${LANDSCAPER_VERSION}/${LANDSCAPER_FILENAME}
RUN curl -L ${HELM_URL} | tar zxv -C /tmp \
    && cp /tmp/linux-amd64/helm /bin/helm \
    && rm -rf /tmp/* \
    && curl -L ${LANDSCAPER_URL} | tar zxv -C /tmp \
    && cp /tmp/landscaper /bin/landscaper \
    && rm -rf /tmp/* \
    && curl https://glide.sh/get | sh \
    && wget https://github.com/stakater/jx-release-version/releases/download/1.1.0/jx-release-version_v1.1.0_Linux_x86_64.tar.gz \
    && tar -xzvf jx-release-version_v1.1.0_Linux_x86_64.tar.gz -C /tmp \
    && cd /tmp \
    && chmod +x jx-release-version \
    && mv jx-release-version /bin/jx-release-version \
    && rm -rf /tmp/* 
ARG GORELEASER_VERSION=v0.79.0
ARG GORELEASER_FILENAME=goreleaser_Linux_x86_64.tar.gz
ARG GORELEASER_URL=https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/${GORELEASER_FILENAME}
RUN curl -L ${GORELEASER_URL} | tar zxv -C /tmp \
  && cd /tmp \
  && chmod +x goreleaser \
  && mv /tmp/goreleaser /bin/goreleaser \
  && rm -rf /tmp/*
ARG GOLANGCI_VERSION=v1.9.3
ARG GOLANGCI_URL=https://install.goreleaser.com/github.com/golangci/golangci-lint.sh
RUN curl -sfL ${GOLANGCI_URL} | bash -s -- -b /usr/local/bin ${GOLANGCI_VERSION}
ARG DEP_VERSION=v0.5.0
ARG DEP_URL=https://github.com/golang/dep/releases/download/${DEP_VERSION}/dep-linux-386
RUN wget ${DEP_URL} && \
    mv dep-linux-386 /usr/local/bin/dep && \
    chmod +x /usr/local/bin/dep
ARG HRB_VERSION=1.0.0
ARG HRB_URL=https://github.com/stakater/HelmRequirementsBuilder/releases/download/${HRB_VERSION}/HelmRequirementsBuilder
RUN wget ${HRB_URL} && \
    mv HelmRequirementsBuilder /usr/local/bin/ && \
    chmod +x /usr/local/bin/HelmRequirementsBuilder
ARG SONAR_SCANNER_VERSION=3.3.0.1492
ARG SONAR_SCANNER_DIR=sonar-scanner-cli
ARG SONAR_SCANNER_URL=https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip
RUN wget ${SONAR_SCANNER_URL} -P /tmp \
  && unzip /tmp/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -d /tmp \
  && chmod +x /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/* \
  && mkdir -p /bin/${SONAR_SCANNER_DIR} \
  && mv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/* /bin/${SONAR_SCANNER_DIR}/ \
  && ln -s /bin/${SONAR_SCANNER_DIR}/bin/sonar-scanner /bin/sonar-scanner \
  && ln -s /bin/${SONAR_SCANNER_DIR}/bin/sonar-scanner-debug /bin/sonar-scanner-debug \
  && rm -rf /tmp/*
ARG ECR_CREDENTIALS_HELPER_VERSION=0.3.1
ARG ECR_CREDENTIALS_HELPER_URL=https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${ECR_CREDENTIALS_HELPER_VERSION}/linux-amd64/docker-credential-ecr-login
RUN wget ${ECR_CREDENTIALS_HELPER_URL} \
  && mv docker-credential-ecr-login /usr/bin \
  && chmod +x /usr/bin/docker-credential-ecr-login
ADD bootstrap.sh /
ADD binaries/* /usr/local/bin/
ENTRYPOINT ["/bootstrap.sh"]
