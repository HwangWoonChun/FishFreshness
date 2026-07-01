# Branch Protection for `main`

`main` is protected with the rules below. Direct pushes are blocked; merge via Pull Request only.

## Applied Rules

| Rule | Setting |
|------|---------|
| Require pull request before merging | Enabled |
| Required approvals | 0 (solo maintainer; increase when collaborators join) |
| Dismiss stale pull request approvals | Disabled |
| Require conversation resolution | Enabled |
| Require linear history | Disabled |
| Include administrators | Enabled |
| Allow force pushes | Disabled |
| Allow deletions | Disabled |
| Delete head branches after merge | Enabled (repository setting) |

Status checks are not required yet. Enable **Require status checks to pass** after CI is added.

## Apply or Update (maintainers)

From a machine with [GitHub CLI](https://cli.github.com/) authenticated as a repo admin:

```bash
./.github/scripts/setup-branch-protection.sh
```

Or manually in GitHub: **Settings → Branches → Branch protection rules → Add rule** for `main`, matching the table above.

## Temporary Bypass

Admins can still merge their own PRs without external approval. To require a second reviewer later, set **Required approvals** to `1` in the script or GitHub UI.
