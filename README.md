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
4. Update/renew the fine-grained PAT to include the new repository.
5. Grant the new repository access to the `DEPENDABOT_TEAMS_WEBHOOK` organisation secret (see [Teams notifications](#teams-notifications)).

## Repository layout

| Path | Purpose |
| --- | --- |
| `.github/sync.yaml` | The list of repositories that should receive the Dependabot configuration. |
| `templates/dependabot.yaml` | The Dependabot configuration distributed to each listed repository. |
| `templates/dependabot-checklist.yaml` | Workflow distributed to each listed repository that posts a reviewer checklist and a Teams notification on Dependabot PRs. |
| `templates/CODEOWNERS` | Assigns the reviewer group to Dependabot PRs. |
| `.github/workflows/notify-teams.yaml` | Reusable workflow, called from each listed repository, that posts new Dependabot PRs to Teams. |

## Adding a reviewer

To add a reviewer to dependabot PRs add them to the GitHub organisation's group dependabot-update-reviewers.

## Teams notifications

When Dependabot opens a pull request in a listed repository, a card linking to it is posted to a Teams channel.

The synced checklist workflow calls the reusable [`notify-teams.yaml`](.github/workflows/notify-teams.yaml) workflow in this repository. Changes to it take effect immediately in all listed repositories once merged to `main`.

The channel's webhook URL is held in the `DEPENDABOT_TEAMS_WEBHOOK` **organisation** Actions secret. It must be an organisation secret as reusable workflows run in the caller's context and cannot read secrets from this repository. Access should be restricted to the repositories listed in `sync.yaml`.

To set up or change the channel:

1. In the Teams channel, open **Workflows** and create a flow from the *Send webhook alerts to a channel* template.
2. Copy the generated URL into the `DEPENDABOT_TEAMS_WEBHOOK` organisation secret.

### Opting out

Notifications are on by default. To turn them off for a repository, add a repository **variable** (Settings → Secrets and variables → Actions → Variables) named `DEPENDABOT_TEAMS_NOTIFY` with the value `false`.

An opted-out repository does not need access to the `DEPENDABOT_TEAMS_WEBHOOK` secret.

## Licence

See [LICENSE](LICENSE).
