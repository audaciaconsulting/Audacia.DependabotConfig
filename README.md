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
| `templates/dependabot-checklist.yaml` | Workflow distributed to each listed repository that posts a reviewer checklist, a Teams notification and a tracking issue for Dependabot PRs. |
| `templates/CODEOWNERS` | Assigns the reviewer group to Dependabot PRs. |
| `.github/workflows/notify-teams.yaml` | Reusable workflow, called from each listed repository, that posts new Dependabot PRs to Teams. |
| `.github/workflows/dependabot-issue.yaml` | Reusable workflow, called from each listed repository, that opens and closes a tracking issue for each Dependabot PR. |

## Adding a reviewer

To add a reviewer to dependabot PRs add them to the GitHub organisation's group dependabot-update-reviewers.

## Teams notifications

New Dependabot PRs are posted to a Teams channel by [`notify-teams.yaml`](.github/workflows/notify-teams.yaml).

The channel's webhook URL is stored in the `DEPENDABOT_TEAMS_WEBHOOK` organisation secret, which each listed repository needs access to. To change the channel, create a flow in the channel's **Workflows** from the *Send webhook alerts to a channel* template and update the secret with the generated URL.

## Tracking issues

[`dependabot-issue.yaml`](.github/workflows/dependabot-issue.yaml) raises an issue for each Dependabot PR and closes it when the PR is merged (*completed*) or closed without merging (*not planned*). Issues must be enabled in the repository.

The issue is matched to its PR by the PR URL in the issue body, so leave that line intact. A `Tracking issue: #n` comment is also posted on the PR for reference.

## Opting out

Both features are on by default. To turn one off for a repository, set the repository Actions variable below to `false`:

| Feature | Variable |
| --- | --- |
| Teams notifications | `DEPENDABOT_TEAMS_NOTIFY` |
| Tracking issues | `DEPENDABOT_TRACKING_ISSUES` |

## Licence

See [LICENSE](LICENSE).
