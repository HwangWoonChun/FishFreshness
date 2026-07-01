# Contributing to FishFreshness

FishFreshness는 GitHub Flow 기반의 브랜치 전략을 사용합니다. `main`은 항상 빌드 가능한 안정 브랜치이며, 모든 변경은 feature/fix 브랜치에서 작업한 뒤 Pull Request로 머지합니다.

## Branch Strategy

| Branch | Purpose | Lifetime |
|--------|---------|----------|
| `main` | Production-ready code. App Store release baseline. | Permanent |
| `feature/*` | New features | Delete after merge |
| `fix/*` | Bug fixes | Delete after merge |
| `chore/*` | Docs, config, refactoring | Delete after merge |
| `release/*` | Pre-release cleanup (optional) | Delete after merge |

`develop` 브랜치는 사용하지 않습니다. 팀 규모가 커지거나 TestFlight 배포 주기가 늘어나면 도입을 검토합니다.

## Branch Naming

```
feature/short-description   e.g. feature/improve-result-ui
fix/short-description       e.g. fix/camera-permission-crash
chore/short-description     e.g. chore/update-xcode-setup-docs
release/version             e.g. release/1.2.0
```

- Use lowercase and hyphens.
- Keep names short and descriptive.
- Include an issue number when applicable: `feature/12-freshness-history`.

## Workflow

### 1. Start from latest `main`

```bash
git checkout main
git pull origin main
```

### 2. Create a working branch

```bash
git checkout -b feature/your-feature-name
```

### 3. Commit changes

Write clear commit messages in the existing project style:

```
Improve fish analysis accuracy and polish result UI.
Integrate Core ML models for species and freshness classification.
```

- Start with a capital letter.
- Use the imperative mood.
- End with a period.
- One logical change per commit when possible.

### 4. Push and open a Pull Request

```bash
git push -u origin feature/your-feature-name
```

Open a PR against `main`. Describe what changed and why. Self-review the diff before requesting review.

### 5. Merge and clean up

After the PR is merged:

```bash
git checkout main
git pull origin main
git branch -d feature/your-feature-name
```

## Pull Request Guidelines

- Keep PRs focused on a single feature or fix.
- Ensure the project builds in Xcode before opening a PR.
- Link related issues when available.
- Address review feedback with additional commits on the same branch.

## Releases

Tag `main` when submitting to the App Store or cutting a release:

```bash
git tag -a v1.0.0 -m "Initial App Store release"
git push origin v1.0.0
```

Use [Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`.

| Tag | When |
|-----|------|
| `v1.0.0` | App Store release |
| `v1.0.1` | Hotfix |
| `v1.1.0` | New features |

## Hotfixes

For urgent production fixes:

```bash
git checkout main
git pull origin main
git checkout -b fix/hotfix-description
# fix, commit, push, open PR, merge, tag
```

## Protected `main` Branch

Direct pushes to `main` are not allowed. All changes must go through a Pull Request. See [GitHub branch protection setup](.github/BRANCH_PROTECTION.md) for the applied rules.
