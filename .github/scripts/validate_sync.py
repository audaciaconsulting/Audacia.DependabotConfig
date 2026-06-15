#!/usr/bin/env python3
"""Sanity checks for sync/sync.yaml.

Fails (non-zero exit) if:
  - sync.yaml is missing or not valid YAML
  - any repo entry is not in "owner/name" form
  - any file mapping is missing a source/dest, or the source file does not exist
"""
import os
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SYNC_PATH = os.path.join(ROOT, ".github", "sync.yaml")


def fail(msg):
    print(f"::error::{msg}")
    sys.exit(1)


def main():
    if not os.path.isfile(SYNC_PATH):
        fail(f"sync config not found at {SYNC_PATH}")

    with open(SYNC_PATH, "r", encoding="utf-8") as f:
        try:
            config = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            fail(f"sync.yaml is not valid YAML: {exc}")

    if not isinstance(config, dict):
        fail("sync.yaml must be a mapping at the top level")

    errors = []

    for group_name, group in config.items():
        if not isinstance(group, dict):
            errors.append(f"group '{group_name}' must be a mapping")
            continue

        # repos: newline-delimited string or a list
        repos_raw = group.get("repos")
        if repos_raw is None:
            errors.append(f"group '{group_name}' has no 'repos'")
        else:
            if isinstance(repos_raw, str):
                repos = [r.strip() for r in repos_raw.splitlines() if r.strip()]
            elif isinstance(repos_raw, list):
                repos = [str(r).strip() for r in repos_raw if str(r).strip()]
            else:
                repos = []
                errors.append(f"group '{group_name}': 'repos' must be a list or string")

            if not repos:
                errors.append(f"group '{group_name}': 'repos' is empty")

            for repo in repos:
                parts = repo.split("/")
                if len(parts) != 2 or not all(parts):
                    errors.append(
                        f"group '{group_name}': repo '{repo}' is not in 'owner/name' form"
                    )

        # files: list of {source, dest} (or shorthand strings)
        files = group.get("files")
        if files is None:
            errors.append(f"group '{group_name}' has no 'files'")
        elif not isinstance(files, list):
            errors.append(f"group '{group_name}': 'files' must be a list")
        else:
            for entry in files:
                if isinstance(entry, str):
                    source = entry
                elif isinstance(entry, dict):
                    source = entry.get("source")
                    if not source:
                        errors.append(
                            f"group '{group_name}': a file mapping is missing 'source'"
                        )
                        continue
                    if not entry.get("dest"):
                        errors.append(
                            f"group '{group_name}': file mapping for '{source}' is missing 'dest'"
                        )
                else:
                    errors.append(f"group '{group_name}': invalid file entry: {entry!r}")
                    continue

                source_path = os.path.join(ROOT, source)
                if not os.path.exists(source_path):
                    errors.append(
                        f"group '{group_name}': source file '{source}' does not exist"
                    )

    if errors:
        for err in errors:
            print(f"::error::{err}")
        sys.exit(1)

    print("sync.yaml is valid.")


if __name__ == "__main__":
    main()
