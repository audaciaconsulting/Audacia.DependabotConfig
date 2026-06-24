# Overview

Centralised [Dependabot](https://docs.github.com/en/code-security/dependabot) configuration for Audacia repositories, with an automated flow for rolling out changes across the organisation.

Rather than maintaining `.github/dependabot.yaml` by hand in every repository, this repository holds a single source of truth and propagates it as reviewable pull requests wherever it's needed.

## How it works

1. Every Audacia repository that should run Dependabot is listed in [`sync.yaml`](.github/sync.yaml).
2. Pushing `sync.yaml` to `main` triggers the sync workflow.
3. The workflow raises a pull request in each listed repository, adding (or updating) `.github/dependabot.yaml`.
4. Each pull request follows Audacia's contribution guidelines and is reviewed and merged by the owning team.

## Adding a repository

1. Add the repository to `sync.yaml`.
2. Open a pull request against `main`.
3. Once merged, the sync workflow runs and opens the corresponding pull request in the target repository.

## Repository layout

| Path | Purpose |
| --- | --- |
| `sync.yaml` | The list of repositories that should receive the Dependabot configuration. |
| `.github/dependabot.yaml` | The Dependabot configuration distributed to each listed repository. |

## Licence

See [LICENSE](LICENSE).

