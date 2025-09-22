# Copyright 2021 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------
# This Dockerfile is designed to build the cross-platform CLI binaries
# as defined by the 'release-cli' target in the Makefile.
#
# It uses a multi-stage build to first compile the UI and then
# build the Go binaries for various operating systems and architectures.
# ------------------------------------------------------------------------


####################################################################################################
# Argo CD UI stage
####################################################################################################
FROM registry.access.redhat.com/ubi8/nodejs-20 AS argocd-ui

USER root

# Install Yarn
WORKDIR /usr/src/app
COPY ["prefetch/yarn/package.json", "prefetch/yarn/package-lock.json", "./"]
RUN npm install --prefer-offline --no-progress --non-interactive
ENV YARN="/usr/src/app/node_modules/.bin/yarn"
RUN $YARN --version

WORKDIR /usr/src/app/argo-cd/ui

COPY ["sources/argo-cd/ui/package.json", "sources/argo-cd/ui/yarn.lock", "./"]

RUN $YARN  install --no-progress --non-interactive --prefer-offline --network-timeout 200000 && \
    $YARN cache clean

COPY ["sources/argo-cd/ui/", "."]

ARG ARGO_VERSION=latest
ENV ARGO_VERSION=$ARGO_VERSION
RUN NODE_ONLINE_ENV='offline' NODE_ENV='production' $YARN build

####################################################################################################
# Argo CD Build stage which performs the actual build of ArgoCD-cli binaries
# This stage uses the Go toolset to build the binaries for different platforms
####################################################################################################
FROM registry.redhat.io/rhel8/go-toolset:1.24.6 AS release-cli-build

USER root

COPY sources/argo-cd /go/src/github.com/argoproj/argo-cd
WORKDIR /go/src/github.com/argoproj/argo-cd

COPY --from=argocd-ui /usr/src/app/argo-cd/ui/dist/app ./ui/dist/app

ARG CI_ARGO_CD_VERSION
ARG CI_ARGO_CD_COMMIT
ARG CI_VERSION
ENV EXTRA_BUILD_INFO="{Vendor Information: Red Hat OpenShift GitOps version: $CI_VERSION}"

ENV PACKAGE="github.com/argoproj/argo-cd/v3/common" \
    GIT_TREE_STATE="clean"

RUN go mod download

RUN go clean -cache
RUN rm -rf dist && mkdir -p dist


RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for darwin/amd64..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-darwin-amd64 ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for darwin/arm64..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-darwin-arm64 ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for linux/amd64..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-linux-amd64 ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for linux/arm64..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-linux-arm64 ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for linux/ppc6le..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=linux GOARCH=ppc6le GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-linux-ppc6le ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for linux/s390x..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=linux GOARCH=s390x GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-linux-s390x ./cmd

RUN \
    set -eux; \
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ'); \
    export KUBECTL_VER=$(go list -m k8s.io/client-go | head -n 1 | rev | cut -d' ' -f1 | rev); \
    LDFLAGS="-w -s -X ${PACKAGE}.version=${CI_ARGO_CD_VERSION} -X ${PACKAGE}.buildDate=${BUILD_DATE} -X ${PACKAGE}.gitCommit=${CI_ARGO_CD_COMMIT} -X ${PACKAGE}.gitTreeState=${GIT_TREE_STATE} -X ${PACKAGE}.kubectlVersion=${KUBECTL_VER} -X '${PACKAGE}.extraBuildInfo=${EXTRA_BUILD_INFO}'"; \
    echo "Building for windows/amd64..."; \
    GOMAXPROCS=1 CGO_ENABLED=0 GOOS=windows GOARCH=amd64 GODEBUG="tarinsecurepath=0,zipinsecurepath=0" \
    go build -v -ldflags "$LDFLAGS" -o dist/argocd-windows-amd64.exe ./cmd

RUN \
    set -eux; \
    echo "Packaging binaries for Konflux release..."; \
    mkdir -p /releases; \
    mv dist/* /releases/; \
    cd /releases; \
    tar -czf argocd-darwin-amd64.tar.gz argocd-darwin-amd64; \
    tar -czf argocd-darwin-arm64.tar.gz argocd-darwin-arm64; \
    tar -czf argocd-linux-amd64.tar.gz argocd-linux-amd64; \
    tar -czf argocd-linux-arm64.tar.gz argocd-linux-arm64; \
    tar -czf argocd-linux-ppc6le.tar.gz argocd-linux-ppc6le; \
    tar -czf argocd-linux-s390x.tar.gz argocd-linux-s390x; \
    tar -czf argocd-windows-amd64.tar.gz argocd-windows-amd64.exe; \
    # Clean up the uncompressed binaries to save space in the final layer. \
    rm argocd-*; \
    echo "Konflux packaging complete. Artifacts are in /releases."
