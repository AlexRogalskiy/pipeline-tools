FROM stakater/pipeline-tools:v1.16.4 

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
