# Organization configuration

Each workspace selects its organization through `github_owner`. Optional
overrides can live in `config/orgs/<github_owner>/`; a missing org directory
means shared defaults apply. Repository metadata comes from the selected
organization's live GitHub data.

Shared policy values stay in `config/commit-message-pattern.txt` and
`config/rulesets-defaults.yml`.

Required workflow gates are enabled by `config/orgs/<github_owner>/required-workflows.yml`.

Default-branch merge restrictions use `config/orgs/<github_owner>/merge-restriction.yml` with a `repos` list.
The ruleset is created only when that list is non-empty.
