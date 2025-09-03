# Copyright 2024 Red Hat
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

####################################################################################################
FROM registry.access.redhat.com/ubi8/ubi

RUN dnf install -y \
    rpm-build \
    curl \
    yq \
    jq \
    sed \
    gawk \
    tar && \

    dnf clean all

WORKDIR /workspace

COPY . .

CMD ["/workspace/pre-build-script.sh"]

LABEL \
    name="openshift-gitops-1/microshift-gitops-rpm-rhel8" \
    License="Apache 2.0" \
    com.redhat.component="openshift-gitops-microshift-gitops-rpm-container" \
    com.redhat.delivery.appregistry="false" \
    summary="Red Hat OpenShift GitOps microshift-gitops-rpm" \
    io.openshift.expose-services="" \
    io.openshift.tags="openshift,gitops,extensions,argocd" \
    io.k8s.display-name="Red Hat OpenShift GitOps microshift-gitops-rpm" \
    maintainer="William Tam <wtam@redhat.com>" \
    description="Red Hat OpenShift GitOps microshift-gitops-rpm" \
    io.k8s.description="Red Hat OpenShift GitOps microshift-gitops-rpm"
