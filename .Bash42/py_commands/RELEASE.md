# Bash42 Release Publishing Guide

This document explains how to publish a new Bash42 release in the format expected by the project.

## Overview

Bash42 uses a release helper script that:

- bumps the project version in [.Bash42/config.json](.Bash42/config.json)
- creates a zip archive named `Bash42.zip`
- appends the new version metadata to [versions.json](versions.json)
- expects the GitHub release tag to follow the format `vX.Y.Z`

The install flow in [README.md](README.md) downloads the latest release asset from GitHub using the release asset name `Bash42.zip`.

## Prerequisites

Before publishing a release, make sure:

- the project is committed and the working tree is clean
- you have access to the GitHub repository
- the release asset will be uploaded as `Bash42.zip`
- the GitHub tag matches the version in the config metadata

## 1) Create the next version

From the project root:

```bash
cd /home/lmuny/Documents/Dev/Projects/Bash42
python ./.Bash42/py_commands/create_version_b42.py
```

This script will:

- show the current version and suggest the next valid version
- update the version in [.Bash42/config.json](.Bash42/config.json)
- create the zip archive
- update [versions.json](versions.json) with the new release metadata
- ask for changelog lines until you finish entering them

## 2) Review the generated metadata

Confirm the following before publishing:

- the version in [.Bash42/config.json](.Bash42/config.json) is correct
- the new entry in [versions.json](versions.json) contains the correct tag URL, SHA256 hash, and changelog
- the archive is present in the project root as `Bash42.zip`

## 3) Commit and push the release metadata

```bash
git add .Bash42/config.json versions.json
git commit -m "Release vX.Y.Z"
git push origin main
```

Replace `X.Y.Z` with the actual version you created.

## 4) Create the GitHub tag and release

### Option A: GitHub CLI

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --notes "Release notes for vX.Y.Z" \
  ./Bash42.zip
```

### Option B: GitHub web UI

1. Push the commit and tag to GitHub.
2. Open the repository Releases page.
3. Create a new release with tag `vX.Y.Z`.
4. Upload the file `Bash42.zip`.
5. Add the changelog notes.

## 5) Verify the published install URL

The expected asset URL format is:

```text
https://github.com/SaikoroAsh/Bash42/releases/download/vX.Y.Z/Bash42.zip
```

And the latest release download URL is:

```text
https://github.com/SaikoroAsh/Bash42/releases/latest/download/Bash42.zip
```

## Release checklist

- [ ] version created with the helper script
- [ ] changelog added
- [ ] metadata updated in [versions.json](versions.json)
- [ ] release tag created
- [ ] `Bash42.zip` uploaded to GitHub
- [ ] install URL verified
- [ ] users can update with `b42`

## Notes

The project’s release flow is intentionally simple: generate the asset, publish the tag, and upload the zip archive. The metadata file [versions.json](versions.json) is what the updater uses to know about available versions.
