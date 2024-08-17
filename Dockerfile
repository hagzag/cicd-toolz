FROM quay.io/argoproj/argocd:${ARGOCD_VERSION:-latest} AS argocd
FROM docker.io/dtzar/helm-kubectl:${KUBECTL_VERSION:-latest} AS kubectl
FROM docker.io/alpine/terragrunt:${TERRAGRUNT_VERSION:-1.4.5-eks} AS terragrunt
FROM docker.io/alpine:latest

COPY --from=argocd /usr/local/bin/argocd         /usr/local/bin/
COPY --from=argocd /usr/local/bin/helm           /usr/local/bin/
COPY --from=argocd /usr/local/bin/kustomize      /usr/local/bin/
COPY --from=kubectl /usr/local/bin/kubectl      /usr/local/bin/
COPY --from=terragrunt /bin/terraform            /usr/local/bin/
COPY --from=terragrunt /usr/local/bin/terragrunt /usr/local/bin/

RUN apk update \
    && apk add --no-cache curl jq yq bash bash-completion \
    && apk add --no-cache openssh glab github-cli jsonnet go-task \
    && apk add --no-cache nodejs  npm \
    && apk add --no-cache python3 py3-pip \
    && apk add --no-cache aws-cli \
    && apk add --no-cache vim \
    && rm -rf /var/cache/apk/*

RUN npm install -g  yarn\
                    semantic-release \
                    @semantic-release/git \
                    @semantic-release/gitlab \
                    @semantic-release/github \
                    semantic-release-docker \
                    semantic-release-helm3 \
                    @semantic-release/release-notes-generator \
                    @semantic-release/commit-analyzer \
                    @semantic-release/changelog \
                    @semantic-release/exec

RUN ln -s /usr/bin/go-task /usr/bin/task
RUN curl https://raw.githubusercontent.com/go-task/task/main/completion/bash/task.bash -o /usr/local/share/task.bash_completion

ENV HELM_EXPERIMENTAL_OCI=1

RUN cat <<EOF > ~/.bash_profile
test -f /etc/bash/bash_completion.sh && . /etc/bash/bash_completion.sh
test -f /usr/local/share/task.bash_completion && . /usr/local/share/task.bash_completion
EOF
RUN chmod +x ~/.bash_profile

ENTRYPOINT ["/bin/bash", "-l", "-c"]
