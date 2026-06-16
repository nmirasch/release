# Argo CD UI Dependencies via Hermeto Generic Fetcher

Hermeto generic-fetcher lockfile for all npm tarballs referenced by `sources/argo-cd/ui/pnpm-lock.yaml`.

## Regenerate

When the `sources/argo-cd` submodule is bumped and `pnpm-lock.yaml` changes:

```bash
make sources   # sync submodule per config.yaml
./hack/generate-pnpm-artifacts-lock.py ui-lockfile sources/argo-cd/ui/pnpm-lock.yaml \
  -o prefetch/argocd-ui/artifacts.lock.yaml
```

Commit the updated `artifacts.lock.yaml` alongside the `config.yaml` submodule bump.

## Notes

- Git-hosted packages without integrity in `pnpm-lock.yaml` (e.g. `argo-ui`) use precomputed checksums in `hack/generate-pnpm-artifacts-lock.py`.
- ~1,300 artifacts — first prefetch is slow; Konflux/Cachi2 caches subsequent builds.
