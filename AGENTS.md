# AGENTS.md

## Project Overview

Builds a Docker image that compiles the AWS CLI v2 from source on Alpine Linux. The compiled binary is published to GitHub Container Registry (`ghcr.io/sparkfabrik/docker-alpine-aws-cli`) so downstream Alpine images can copy `aws` in via a multi-stage `COPY --from=`.

The `Dockerfile` is a two-stage build: a `python:*-alpine*` builder stage clones `aws/aws-cli` at a pinned tag, compiles it with `make-exe`, and installs it; the final `alpine` stage carries only the compiled CLI plus `bash` and `groff`.

**Tech stack:** Docker (multi-stage, buildx), Alpine Linux, Python (builder stage only, to compile AWS CLI v2), Make, GitHub Actions.

## Setup

Everything runs in Docker via `make` and `docker buildx`. No local Python or AWS CLI required.

```bash
make build                 # Build the default (latest) tag: 2.35.15-alpine3.23
make print-latest-image-tag # Print the LATEST_VERSION used by CI to tag `latest`
```

Individual version combinations are built with their own targets:

```bash
make build-2.35.15-3.23    # AWS CLI 2.35.15, Python 3.12.13, Alpine 3.23
make build-2.35.15-3.20    # AWS CLI 2.35.15, Python 3.12.4,  Alpine 3.20
make build-2.33.2-3.23
make build-2.33.2-3.20
```

The Alpine 3.23 base ships Python 3.12 without `distutils`, which aws-cli's `make-exe`
still imports; the Dockerfile installs `setuptools<74` in the builder to restore it.

Each target sets `AWS_CLI_VERSION`, `PYTHON_VERSION`, `ALPINE_VERSION` and calls `build-template`, which runs `docker buildx build --load` with those build args.

## Key Conventions

- **Docker-only.** All builds go through `docker buildx`. Never install the AWS CLI or Python locally to test.
- **Versions are pinned in three places that must agree:**
  - `Dockerfile` `ARG` defaults (`PYTHON_VERSION`, `ALPINE_VERSION`, `AWS_CLI_VERSION`).
  - `Makefile` per-target overrides and `LATEST_VERSION`.
  - The CI matrix in `.github/workflows/docker-publish.yml` (tag format `<awscli>-<python>-<alpine>`).
    A version bump touches all three.
- **Keep the build matrix small.** By project policy only the latest two AWS CLI versions are kept (see comments in the Makefile and workflow). Drop the oldest when adding a new one.
- **AWS CLI v1 lives on the `v2` branch note.** The Dockerfile comment points to a `v2` branch for v2 docs; the current build compiles v2 from the pinned git tag.
- The build deletes unused `completions-1*.json` and `examples-1.json` data files to shrink the image — preserve that cleanup when editing the builder stage.

## Git Workflow

### Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `build`.
**Scope** is optional — use the affected component (e.g. `deps`).

Keep the description lowercase, imperative, no period. This repo uses the `sf-commit-convention` skill — consult it before every commit.

### Branching

- Branch naming: `feat/`, `fix/`, `chore/`, `test/`, `docs/` prefix + kebab-case description (e.g. `feat/upgrade-awscli-2.34`, `fix/install-bash`).
- **Never push directly to `main`.** Always create a feature branch and open a pull request.

### Rebasing

- Always rebase onto `main` before pushing. No merge commits.
- Use `--force-with-lease` (never `--force`) after rebasing.
- Rebase before the first push, before opening a PR, and whenever `main` advances.

## Version Management

This repo has no language package manager — dependencies are pinned versions of external components.

- **AWS CLI version:** the git tag cloned in the Dockerfile builder stage. Set via `AWS_CLI_VERSION` in the Makefile targets and Dockerfile `ARG`.
- **Python / Alpine versions:** base image tags, pinned via `PYTHON_VERSION` / `ALPINE_VERSION`.
- **GitHub Actions:** managed by Renovate (`renovate.json` extends `sparkfabrik/renovatebot-default-configuration`).
- **Dockerfile updates are Renovate-disabled on purpose** (`renovate.json`) — base image and AWS CLI versions must be checked and bumped manually.

### Dependency Safety

Before bumping any pinned version, verify it against the live source:

1. **Never assume you know the latest version.** Your training data is outdated. Always check the live source before bumping.
2. **Check the live source:**

   AWS CLI (git tags):

   ```bash
   git ls-remote --tags --refs https://github.com/aws/aws-cli.git | awk -F/ '{print $NF}' | grep '^2\.' | sort -V | tail -5
   ```

   Python Alpine image tags (Docker Hub):

   ```bash
   curl -s "https://hub.docker.com/v2/repositories/library/python/tags?page_size=100&name=alpine" | jq -r '.results[].name' | grep alpine | head
   ```

   Alpine image tags:

   ```bash
   curl -s "https://hub.docker.com/v2/repositories/library/alpine/tags?page_size=50" | jq -r '.results[].name' | sort -V | tail
   ```

3. **Verify the AWS CLI tag actually builds** on the chosen Python + Alpine combination before committing — the compile step (`make-exe`) is version-sensitive.
4. **Update all three locations** (Dockerfile ARG, Makefile, CI matrix) in the same change and keep the matrix to the latest two AWS CLI versions.

## Build Gotchas

- The Python patch version is coupled to the Alpine minor. Only `python:<patch>-alpine<minor>` tags that exist on Docker Hub are usable. `python:3.12.4-alpine3.23` does not exist; Alpine 3.20 has no Python newer than `3.12.10`; Alpine 3.23 has `3.12.13`. Check Docker Hub for the pair before choosing a `PYTHON_VERSION` — you cannot pin an arbitrary Python patch against an arbitrary Alpine minor.
- aws-cli's `make-exe` imports `distutils`, which the Python 3.12 stdlib no longer ships. Older Alpine Python images built anyway because their bundled `setuptools` shimmed `distutils`; `setuptools >= 74` (shipped by the Alpine 3.23 Python image) dropped that shim. The builder installs `setuptools<74` to restore it. Removing that line breaks the build with `ModuleNotFoundError: No module named 'distutils'`.
- aws-cli 2.33.2 prints `UserWarning: pkg_resources is deprecated as an API` on stderr for every command. It is benign and was fixed upstream by 2.35.x. `PYTHONWARNINGS` does not suppress it — the frozen PyInstaller binary emits it during bootstrap, before any warning filter applies. Do not spend time silencing it; it ages out when 2.33.2 leaves the latest-two window.
- `RUN . venv/bin/activate` in the Dockerfile is a no-op. Each `RUN` is a fresh shell, so the activation does not carry to the next layer. `make-exe` manages its own venv internally, so the line has no effect either way.
- Build every matrix combination locally before committing a version bump. The compile step is version-sensitive, so a change that builds for one AWS CLI / Python / Alpine triple can still fail for another.

## Testing

There is no unit test suite. Verification is the build itself.

- Locally: `make build-<version>` must complete, and the builder stage runs `aws --version` as a smoke check.
- In CI: the `test` job (`.github/workflows/docker-publish.yml`) builds every matrix tag with `push: false` on pull requests and non-`main` branches.

## CI/CD

GitHub Actions workflow `.github/workflows/docker-publish.yml` (`Docker`), triggered on pull requests and pushes to `main`.

### Key Jobs

| Job      | Runs when                   | Purpose                                                                                                                                  |
| -------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `test`   | ref is not `main`           | Build each matrix tag with `--load`, `push: false` — validates the build.                                                                |
| `deploy` | ref is `main` (or `master`) | Build for `linux/amd64,linux/arm64` and push to `ghcr.io`. Logs in via `docker/login-action` pinned by commit SHA, using `GITHUB_TOKEN`. |

Tagging (via `docker/metadata-action`): each version gets a `<awscli>-alpine<alpine>` tag; the version matching `LATEST_VERSION` (from `make print-latest-image-tag`) also gets `latest`; every build gets a `sha`-suffixed tag.

## Command Safety

### Safe (run autonomously)

- `make print-latest-image-tag`
- `make build`, `make build-<version>` (local build only, `--load`, no push)
- `git status`, `git log`, `git diff`
- The registry/version check commands in Dependency Safety.

### Dangerous (ask user first)

- `git push`, opening or merging a pull request.
- Any manual `docker push` to `ghcr.io`.
- Version bumps to AWS CLI / Python / Alpine (change what gets published).
- Editing the CI matrix.

### Destructive (never run)

- `git push --force` (use `--force-with-lease`).
- Deleting published image tags from the registry.
- `docker system prune -af` or similar host-wide teardown.

## Important Rules

- Everything builds in Docker via `make` + `buildx` — never install AWS CLI or Python locally.
- A version bump must update the Dockerfile ARG, the Makefile, and the CI matrix together.
- Keep only the latest two AWS CLI versions in the build matrix.
- Verify any version against its live source before bumping — Dockerfile updates are deliberately Renovate-disabled.
- Never push to `main`; branch and open a PR.
- Follow conventional commits via the `sf-commit-convention` skill.
- Rebase onto `main`, use `--force-with-lease`, never `--force`.
