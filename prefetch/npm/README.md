# npm Prefetch via Nexus

This directory holds npm registry configuration used during Konflux **Cachi2/Hermeto prefetch** for JavaScript dependencies.

## Nexus registry URL

Update `.npmrc` with the Nexus **npm-group** repository URL once confirmed by the platform/Konflux team:

```ini
registry=https://<nexus-host>/repository/npm-group/
always-auth=true
```

The same `.npmrc` is mirrored under `prefetch/yarn/` for the Yarn v1 bootstrap prefetch (`{"type": "npm", "path": "prefetch/yarn"}`).

## How prefetch reaches Nexus

1. **Package registry proxy** — `enable-package-registry-proxy: 'true'` on the shared `build-multi-platform-image` pipeline routes prefetch HTTP requests through the cluster Nexus cache ([Konflux docs](https://konflux-ci.dev/docs/building/prefetching-dependencies/)).
2. **`.npmrc`** — directs `npm`-type prefetch at the Nexus group registry URL.
3. **`.netrc` Secret** — if Nexus requires authentication (e.g. Sonatype User Token), bind a `netrc` workspace on each npm/yarn component PipelineRun. **Never commit credentials to this repository.**

### Sonatype Nexus User Token

Nexus **User Token Name** and **User Token Pass Code** are used as HTTP basic-auth credentials:

| Nexus field | `.netrc` field |
|-------------|----------------|
| User Token Name | `login` |
| User Token Pass Code | `password` |

Example `.netrc` (replace `<nexus-host>` with the hostname from your npm-group URL, without `https://` or path):

```
machine <nexus-host>
login <User Token Name>
password <User Token Pass Code>
```

Create the Secret in the Konflux tenant namespace (credentials stay in the cluster only):

```bash
NEXUS_HOST="<nexus-host>"
TOKEN_NAME="<User Token Name>"
TOKEN_PASS="<User Token Pass Code>"
NAMESPACE="rh-openshift-gitops-tenant"

cat > /tmp/netrc <<EOF
machine ${NEXUS_HOST}
login ${TOKEN_NAME}
password ${TOKEN_PASS}
EOF

oc create secret generic nexus-npm-netrc \
  --namespace="${NAMESPACE}" \
  --from-file=.netrc=/tmp/netrc

rm -f /tmp/netrc
```

PipelineRuns for console-plugin, argocd, and kubectl-argo-rollouts-cli reference this Secret via the `netrc` workspace.

## Components using npm/yarn prefetch

See `prefetch/yarn/README.md` for the Yarn v1 bootstrap workaround and Tekton `prefetch-input` examples.
