#!/usr/bin/env python3
"""Generate Hermeto generic-fetcher lockfile from pnpm-lock.yaml.

Usage:
  # Argo CD UI dependencies (requires pnpm-lock.yaml):
  ./hack/generate-pnpm-artifacts-lock.py ui-lockfile sources/argo-cd/ui/pnpm-lock.yaml \\
      -o prefetch/argocd-ui/artifacts.lock.yaml

Hermeto generic fetcher docs:
  https://hermetoproject.github.io/hermeto/generic/
"""

from __future__ import annotations

import argparse
import base64
import re
import sys
from pathlib import Path

# Git-hosted packages without integrity in pnpm-lock.yaml (checksum computed offline).
KNOWN_TARBALLS_WITHOUT_INTEGRITY = {
    "https://codeload.github.com/argoproj/argo-ui/tar.gz/c089d1d2d84df87f3712ae661273a5ab0d1ef3b0": (
        "sha256:8f55602d1cbadcea902f142a7f1d28e19324cfb73eeb219412bbb461ead779bc"
    ),
}


def integrity_to_checksum(integrity: str) -> str:
    algo, b64hash = integrity.split("-", 1)
    return f"{algo}:{base64.b64decode(b64hash).hex()}"


def npm_tarball_url(package_key: str) -> str:
    """Build registry.npmjs.org tarball URL from a pnpm lockfile package key."""
    if package_key.startswith("@"):
        scope, rest = package_key[1:].split("/", 1)
        name, version = rest.rsplit("@", 1)
        return f"https://registry.npmjs.org/@{scope}/{name}/-/{name}-{version}.tgz"
    name, version = package_key.rsplit("@", 1)
    return f"https://registry.npmjs.org/{name}/-/{name}-{version}.tgz"


def safe_filename(package_key: str, url: str) -> str:
    if url in KNOWN_TARBALLS_WITHOUT_INTEGRITY:
        return "argocd-ui-argo-ui-git-c089d1d2.tgz"
    sanitized = package_key.replace("@", "_at_")
    sanitized = re.sub(r"[^a-zA-Z0-9._+-]", "_", sanitized)
    return f"argocd-ui-{sanitized}.tgz"


def parse_pnpm_lockfile(path: Path) -> list[dict]:
    text = path.read_text()
    packages_start = text.find("\npackages:\n")
    if packages_start == -1:
        raise ValueError(f"{path}: no packages: section found")
    packages_text = text[packages_start:]

    artifacts: list[dict] = []
    seen_urls: set[str] = set()

    block_pattern = re.compile(
        r"^  ([^:\n]+):\n    resolution: \{([^}]+)\}",
        re.MULTILINE,
    )

    for package_key, resolution in block_pattern.findall(packages_text):
        package_key = package_key.strip().strip("'\"")
        if not package_key or package_key.startswith("/"):
            continue
        resolution = resolution.strip()

        tarball_match = re.search(r"tarball:\s*(\S+)", resolution)
        integrity_match = re.search(r"integrity:\s*(\S+)", resolution)

        if tarball_match:
            url = tarball_match.group(1)
        elif integrity_match and "@" in package_key and not package_key.startswith("http"):
            url = npm_tarball_url(package_key)
        else:
            continue

        if url in seen_urls:
            continue
        seen_urls.add(url)

        if integrity_match:
            checksum = integrity_to_checksum(integrity_match.group(1))
        elif url in KNOWN_TARBALLS_WITHOUT_INTEGRITY:
            checksum = KNOWN_TARBALLS_WITHOUT_INTEGRITY[url]
        else:
            print(f"warning: skipping {package_key} — no integrity and no known checksum", file=sys.stderr)
            continue

        artifacts.append(
            {
                "download_url": url,
                "checksum": checksum,
                "filename": safe_filename(package_key, url),
            }
        )

    return artifacts


def write_lockfile(path: Path, artifacts: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "---",
        "metadata:",
        '  version: "1.0"',
        "artifacts:",
    ]
    for artifact in sorted(artifacts, key=lambda a: a["filename"]):
        lines.append(f'  - download_url: "{artifact["download_url"]}"')
        lines.append(f'    checksum: "{artifact["checksum"]}"')
        lines.append(f'    filename: "{artifact["filename"]}"')
    lines.append("")
    path.write_text("\n".join(lines))
    print(f"Wrote {len(artifacts)} artifacts to {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    ui_cmd = sub.add_parser("ui-lockfile", help="Generate UI dependency lockfile from pnpm-lock.yaml")
    ui_cmd.add_argument("pnpm_lock", type=Path)
    ui_cmd.add_argument("-o", "--output", type=Path, default=Path("prefetch/argocd-ui/artifacts.lock.yaml"))

    args = parser.parse_args()

    if args.command == "ui-lockfile":
        if not args.pnpm_lock.is_file():
            print(f"error: {args.pnpm_lock} not found", file=sys.stderr)
            return 1
        write_lockfile(args.output, parse_pnpm_lockfile(args.pnpm_lock))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
