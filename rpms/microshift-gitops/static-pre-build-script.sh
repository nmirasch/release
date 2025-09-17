#!/usr/bin/env bash

set -euxo pipefail
CONFIG=../../config.yaml

# --- Tool Installation ---
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH" # Add our local bin to the PATH

YQ_VERSION="v4.22.1"
YQ_BIN="$BIN_DIR/yq"

# Check if yq is installed in our local bin; if not, download it.
if [ ! -f "$YQ_BIN" ]; then
  echo ">>> Installing yq ${YQ_VERSION}..."
  # Detect OS and Architecture to download the correct binary.
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  case $ARCH in
      x86_64) ARCH="amd64" ;;
      aarch64) ARCH="arm64" ;;
  esac

  curl -sSfLo "$YQ_BIN" "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}"
  chmod +x "$YQ_BIN"
fi

KONFLUX_ARGOCD_IMAGE_NAME="argocd-rhel9"
ARGO_CD_IMAGE_SHA_X86='sha256:5f35a4ed723fa364bd58bc56a9491915ec8bed256a056b07429e1957580b1c4f'
ARGO_CD_IMAGE_SHA_ARM='sha256:8168018c4ffadcda01fea61ec2bf005b556a28966dfdf60cf922a37392bcc987'
REDIS_IMAGE_SHA_X86='sha256:300c0fd54f8f49eba19e6a16745fa7e225f1f66b571c8e02cd098ef45e03d1c8'
REDIS_IMAGE_SHA_ARM='sha256:c796538bad7613deb1fba2bb76e736a6376b25ab97b2f944e67af00e01f5d965'

ARGO_CD_IMAGE_REF=$(KONFLUX_ARGOCD_IMAGE_NAME_VAR="$KONFLUX_ARGOCD_IMAGE_NAME" $YQ_BIN e '(.konfluxImages[] | select(.name == env(KONFLUX_ARGOCD_IMAGE_NAME_VAR))).releaseRef' "$CONFIG")

echo "Successfully found registry: ${ARGO_CD_IMAGE_REF}"

CI_ARGO_CD_UPSTREAM_COMMIT=$($YQ_BIN e '(.sources[] | select(.path == "sources/argo-cd")).commit' "$CONFIG")
GITOPS_VERSION=$($YQ_BIN e '.release.version' "$CONFIG")
GITOPS_RELEASE=$($YQ_BIN e '.release.version' "$CONFIG")
REDIS_IMAGE_REF=$($YQ_BIN e '(.externalImages[] | select(.name == "redis")).image' "$CONFIG")


CI_ARGO_CD_UPSTREAM_URL=https://github.com/argoproj/argo-cd

cat microshift-gitops.spec.in > microshift-gitops.spec

sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_X86|${ARGO_CD_IMAGE_SHA_X86}|g" microshift-gitops.spec
sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_ARM|${ARGO_CD_IMAGE_SHA_ARM}|g" microshift-gitops.spec
sed -i "s|REPLACE_ARGO_CD_IMAGE_URL|${ARGO_CD_IMAGE_REF}|g" microshift-gitops.spec
sed -i "s|REPLACE_ARGO_CD_VERSION|${GITOPS_VERSION}|g" microshift-gitops.spec


sed -i "s|REPLACE_REDIS_CONTAINER_SHA_X86|${REDIS_IMAGE_SHA_X86}|g" microshift-gitops.spec
sed -i "s|REPLACE_REDIS_CONTAINER_SHA_ARM|${REDIS_IMAGE_SHA_ARM}|g" microshift-gitops.spec
sed -i "s|REPLACE_REDIS_IMAGE_URL|${REDIS_IMAGE_REF}|g" microshift-gitops.spec

sed -i "s|REPLACE_MICROSHIFT_GITOPS_RELEASE|${GITOPS_RELEASE}|g" microshift-gitops.spec
sed -i "s|REPLACE_MICROSHIFT_GITOPS_VERSION|${GITOPS_VERSION}|g" microshift-gitops.spec
sed -i "s|REPLACE_CI_ARGO_CD_UPSTREAM_URL|${CI_ARGO_CD_UPSTREAM_URL}|g" microshift-gitops.spec
sed -i "s|REPLACE_CI_ARGO_CD_UPSTREAM_COMMIT|${CI_ARGO_CD_UPSTREAM_COMMIT}|g" microshift-gitops.spec

echo "pre-build-script finished successfully."