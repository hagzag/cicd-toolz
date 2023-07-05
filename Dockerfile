FROM docker.io/argoproj/argocd:${ARGOCD_VERSION:-latest} AS argocd
FROM docker.io/bitnami/kubectl:${KUBECTL_VERSION:-latest} AS kubectl
FROM docker.io/alpine/terragrunt:${TERRAGRUNT_VERSION:-1.4.5-eks} AS terragrunt
FROM docker.io/alpine:3.18.2

ENV OS=linux  
# or "darwin" for OSX, "windows" for Windows.
ENV ARCH=amd64  
# or "386" for 32-bit OSs
ENV GCR_HELPER_VERSION=2.1.5

# ENV TERRAFORM_VERSION=1.3.7
# ENV TERRAGRUNT_VERSION=0.42.2


COPY --from=argocd /usr/local/bin/argocd         /usr/local/bin/
COPY --from=argocd /usr/local/bin/helm           /usr/local/bin/
COPY --from=argocd /usr/local/bin/kustomize      /usr/local/bin/
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/
COPY --from=terragrunt /bin/terraform            /usr/local/bin/
COPY --from=terragrunt /usr/local/bin/terragrunt /usr/local/bin/

RUN apk update \
    && apk add --no-cache curl jq yq bash git nodejs npm openssh glab github-cli jsonnet \
    && rm -rf /var/cache/apk/*

RUN npm install -g semantic-release \
                    @semantic-release/git \
                    @semantic-release/gitlab \
                    @semantic-release/github \
                    semantic-release-docker \
                    semantic-release-helm \
                    semantic-release-helm3 \
                    @semantic-release/release-notes-generator \
                    @semantic-release/commit-analyzer \
                    @semantic-release/changelog \
                    @semantic-release/exec

# docker-credential-gcr

RUN helm plugin install 'https://github.com/chartmuseum/helm-push' 
RUN curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${GCR_HELPER_VERSION}/docker-credential-gcr_${OS}_${ARCH}-${GCR_HELPER_VERSION}.tar.gz" | tar xz docker-credential-gcr \
    && chmod +x docker-credential-gcr && mv docker-credential-gcr /usr/bin/

ENV HELM_EXPERIMENTAL_OCI=1

ENTRYPOINT ["/bin/bash", "-l", "-c"]
