# pnpm Toolchain via Hermeto Generic Fetcher

Related: [GITOPS-9932](https://redhat.atlassian.net/browse/GITOPS-9932)

Hermeto does not support `pnpm` natively yet ([hermeto#1251](https://github.com/hermetoproject/hermeto/issues/1251)). This directory uses the **generic fetcher** to prefetch the pnpm toolchain for hermetic Node.js UI builds.

**Scope (exploration):** Argo CD only. `console-plugin` and `kubectl-argo-rollouts-cli` still use yarn today; they should follow the same generic-fetcher pattern once migrated to pnpm upstream.

## Layout

| File | Purpose |
|------|---------|
| `artifacts.lock.yaml` | Hermeto generic lockfile for corepack and pnpm npm tarballs |
| `../argocd-ui/artifacts.lock.yaml` | UI dependency tarballs generated from `pnpm-lock.yaml` |

## Regenerate lockfiles

```bash
# Toolchain (corepack + pnpm versions pinned in the script):
./hack/generate-pnpm-artifacts-lock.py toolchain

# UI dependencies (after bumping sources/argo-cd via config.yaml):
./hack/generate-pnpm-artifacts-lock.py ui-lockfile sources/argo-cd/ui/pnpm-lock.yaml
```

## Tekton prefetch-input

```json
{"type": "generic", "path": "prefetch/pnpm"},
{"type": "generic", "path": "prefetch/argocd-ui"}
```

## Build-time usage

Prefetched files land under `/cachi2/output/deps/generic/` during hermetic builds. See `containers/argocd/Dockerfile` and `hack/seed-pnpm-store.sh`.

## Validation with Hermeto team

This approach is experimental — confirm with #konflux-users / Hermeto maintainers that generic-fetcher is acceptable for pnpm ecosystems before production use.
