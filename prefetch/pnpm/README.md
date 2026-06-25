# pnpm Bootstrap via npm Prefetch

Related: [GITOPS-9932](https://redhat.atlassian.net/browse/GITOPS-9932)

Hermeto does not support `pnpm-lock.yaml` natively yet ([hermeto#1251](https://github.com/hermetoproject/hermeto/issues/1251)).  
This directory bootstraps the **pnpm CLI** using Hermeto's supported `npm` prefetch path (same pattern as `prefetch/yarn`).

**Scope (exploration):** Argo CD only. `console-plugin` and `kubectl-argo-rollouts-cli` still use yarn today.

## Layout

| File | Purpose |
|------|---------|
| `package.json` + `package-lock.json` | Pin `pnpm` package for npm prefetch |
| `../argocd-ui/artifacts.lock.yaml` | UI dependency tarballs generated from `pnpm-lock.yaml` (generic fetcher) |

## Regenerate lockfiles

```bash
# Regenerate npm lockfile for pnpm bootstrap:
npm --prefix prefetch/pnpm install --package-lock-only

# Regenerate UI dependency artifacts lockfile (after bumping sources/argo-cd via config.yaml):
./hack/generate-pnpm-artifacts-lock.py ui-lockfile sources/argo-cd/ui/pnpm-lock.yaml
```

## Tekton prefetch-input

```json
{"type": "npm", "path": "prefetch/pnpm"},
{"type": "generic", "path": "prefetch/argocd-ui"}
```

## Build-time usage

- `{"type":"npm","path":"prefetch/pnpm"}` provides pnpm CLI bootstrap for Dockerfile (`npm install --prefer-offline`).
- `{"type":"generic","path":"prefetch/argocd-ui"}` provides UI tarballs consumed by `hack/seed-pnpm-store.sh`.

## Validation with Hermeto team

This approach is experimental — confirm with #konflux-users / Hermeto maintainers that generic-fetcher is acceptable for pnpm ecosystems before production use.
