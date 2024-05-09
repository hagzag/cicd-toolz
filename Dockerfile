FROM quay.io/argoproj/argocd:${ARGOCD_VERSION:-latest} AS argocd
FROM docker.io/dtzar/helm-kubectl:${KUBECTL_VERSION:-latest} AS kubectl
FROM docker.io/alpine/terragrunt:${TERRAGRUNT_VERSION:-1.4.5-eks} AS terragrunt
FROM docker.io/alpine:3.19.1

COPY --from=argocd /usr/local/bin/argocd         /usr/local/bin/
COPY --from=argocd /usr/local/bin/helm           /usr/local/bin/
COPY --from=argocd /usr/local/bin/kustomize      /usr/local/bin/
COPY --from=kubectl /usr/local/bin/kubectl      /usr/local/bin/
COPY --from=terragrunt /bin/terraform            /usr/local/bin/
COPY --from=terragrunt /usr/local/bin/terragrunt /usr/local/bin/

RUN apk update \
    && apk add --no-cache curl jq yq bash git openssh glab github-cli jsonnet \
    && apk add --update nodejs  npm \
    && rm -rf /var/cache/apk/*

RUN npm install -g  yarn\
                    semantic-release \
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

RUN /bin/sh -c curl -sL https://taskfile.dev/install.sh | sh


ENV HELM_EXPERIMENTAL_OCI=1

ENTRYPOINT ["/bin/bash", "-l", "-c"]
