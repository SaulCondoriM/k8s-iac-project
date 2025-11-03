# Version Control Strategy
## Chapter 4: Define Everything as Code - Git Workflow Guide

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Branching Model](#branching-model)
4. [Commit Conventions](#commit-conventions)
5. [Versioning Strategy](#versioning-strategy)
6. [Git Workflow](#git-workflow)
7. [Best Practices](#best-practices)
8. [Pre-Commit Checks](#pre-commit-checks)

---

## 🎯 Overview

This repository follows **Infrastructure as Code** principles from Chapter 4:

### The Five Pillars

1. **Traceability**: Every change is tracked with who, what, when, and why
2. **Rollback**: Any change can be reverted safely
3. **Correlation**: Changes are linked to issues/features
4. **Visibility**: Everyone can see how infrastructure is built
5. **Actionability**: Changes trigger automated validation and deployment

---

## 📁 Repository Structure

```
├── manifests-aws/           # Kubernetes manifests (production)
│   ├── application.yaml     # Main application deployment
│   ├── hpa.yaml             # Horizontal Pod Autoscaler
│   ├── cluster-autoscaler.yaml
│   ├── network-policies-simple.yaml
│   └── ...
│
├── ansible-aws/             # Ansible automation
│   ├── cluster-config.yaml  # EKS cluster definition
│   ├── deploy-eks-autoscaling.yml
│   └── drift-check.sh
│
├── code/                    # Application source
│   ├── main.go              # Go web application
│   ├── Dockerfile           # Container definition
│   └── templates/
│
├── *.md                     # Documentation
│   ├── README.md            # Main documentation
│   ├── QUICKSTART-AWS.md    # Quick start guide
│   ├── ANTI-DRIFT-GUIDE.md  # Chapter 2
│   ├── ZERO-TRUST-GUIDE.md  # Chapter 3
│   └── VERSIONING-GUIDE.md  # This file
│
└── test-*.sh                # Validation scripts
```

### What's Versioned

✅ **Infrastructure definitions** (YAML, Terraform, Ansible)  
✅ **Application code** (Go, Dockerfiles)  
✅ **Configuration** (cluster-config.yaml, ansible.cfg)  
✅ **Automation scripts** (shell scripts, Python)  
✅ **Documentation** (Markdown files)  
✅ **Tests** (test scripts, validation tools)  

### What's NOT Versioned (see .gitignore)

❌ **Secrets** (*.key, *.pem, .env, kubeconfig)  
❌ **Build artifacts** (__pycache__, build/, dist/)  
❌ **IDE files** (.vscode/, .idea/, *.swp)  
❌ **Logs** (*.log, logs/)  
❌ **Dependencies** (node_modules/, venv/)  
❌ **Runtime state** (terraform.tfstate, .terraform/)  

---

## 🌿 Branching Model

We follow **GitHub Flow** - a simplified model perfect for continuous deployment:

```
main (production-ready)
 │
 ├─ feature/add-hpa-scaling ──┐
 │                             │ (PR #1)
 │◄────────────────────────────┘
 │
 ├─ fix/network-policy-typo ──┐
 │                             │ (PR #2)
 │◄────────────────────────────┘
 │
 ├─ docs/update-readme ───────┐
 │                             │ (PR #3)
 │◄────────────────────────────┘
```

### Branch Types

| Type | Format | Purpose | Example |
|------|--------|---------|---------|
| **main** | `main` | Production-ready code | - |
| **feature** | `feature/description` | New features | `feature/add-grafana-dashboard` |
| **fix** | `fix/description` | Bug fixes | `fix/hpa-cpu-threshold` |
| **docs** | `docs/description` | Documentation | `docs/add-monitoring-guide` |
| **refactor** | `refactor/description` | Code improvements | `refactor/ansible-playbook-structure` |
| **test** | `test/description` | New tests | `test/zero-trust-validation` |

### Branch Rules

1. **main is protected** - Always deployable, never commit directly
2. **Short-lived branches** - Create, merge, delete within days
3. **One concern per branch** - Single feature/fix per branch
4. **Sync frequently** - Rebase/merge from main daily

---

## 📝 Commit Conventions

We follow **Conventional Commits** specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Example

```
feat(hpa): increase CPU threshold to 70%

Changed the autoscaling trigger from 50% to 70% CPU to reduce
pod churn during normal traffic spikes. This aligns with our
SLO of 200ms p95 latency.

Tested with 100 concurrent users in Locust, no performance degradation.

Closes #42
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| **feat** | New feature | `feat(monitoring): add DORA metrics dashboard` |
| **fix** | Bug fix | `fix(app): prevent conn busy panic` |
| **docs** | Documentation | `docs: update quickstart guide` |
| **refactor** | Code improvement | `refactor(ansible): simplify drift-check script` |
| **test** | Add/update tests | `test(security): add network policy validation` |
| **chore** | Maintenance | `chore: update dependencies` |
| **ci** | CI/CD changes | `ci: add GitHub Actions workflow` |
| **perf** | Performance | `perf(app): add connection pooling` |
| **revert** | Revert previous | `revert: feat(hpa): increase CPU threshold` |

### Scopes

- `app` - Application code
- `k8s` or `manifests` - Kubernetes manifests
- `ansible` - Ansible playbooks
- `monitoring` - Prometheus/Grafana
- `security` - Network policies, RBAC
- `docs` - Documentation
- `ci` - CI/CD pipelines

### Subject Rules

- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at the end
- Maximum 72 characters
- Be specific but concise

### Body Rules (Optional but Recommended)

- Explain **what** and **why**, not **how**
- Separate from subject with blank line
- Wrap at 72 characters
- Include motivation for the change
- Contrast with previous behavior

### Footer Rules (Optional)

- Reference issues: `Closes #42`, `Fixes #123`, `Refs #456`
- Breaking changes: `BREAKING CHANGE: HPA now requires Metrics Server`
- Co-authors: `Co-authored-by: Name <email@example.com>`

---

## 🏷️ Versioning Strategy

We use **Semantic Versioning** (SemVer) for releases:

### Format: `MAJOR.MINOR.PATCH`

```
v1.2.3
│ │ │
│ │ └─ PATCH: Bug fixes, docs updates
│ └─── MINOR: New features, backward-compatible
└───── MAJOR: Breaking changes
```

### Version Increments

| Change Type | Example | Version |
|-------------|---------|---------|
| **Bug fix** | Fix HPA scaling bug | `1.2.3 → 1.2.4` |
| **New feature** | Add drift monitoring | `1.2.4 → 1.3.0` |
| **Breaking change** | Change HPA API version | `1.3.0 → 2.0.0` |

### Tagging Releases

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial production deployment

Features:
- Dual-layer autoscaling (HPA + Cluster Autoscaler)
- Zero-Trust network security (8 policies)
- Anti-drift monitoring (hourly CronJob)
- DORA metrics dashboard in Grafana

Tested on EKS 1.28 with t3.small nodes"

# Push tag to remote
git push origin v1.0.0

# List tags
git tag -l
```

### Version Tracking

| Version | Date | Changes | Notes |
|---------|------|---------|-------|
| `v1.0.0` | 2024-11-03 | Initial IaC implementation | Chapters 1-4 complete |
| `v1.1.0` | TBD | Add CI/CD pipeline | GitHub Actions |
| `v2.0.0` | TBD | Migrate to GitOps (ArgoCD) | Breaking change |

---

## 🔄 Git Workflow

### 1. Start New Work

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/add-prometheus-alerts

# Verify branch
git branch
```

### 2. Make Changes

```bash
# Edit files
vim manifests-aws/prometheus-alerts.yaml

# Check status
git status

# View changes
git diff
```

### 3. Stage and Commit

```bash
# Stage specific files
git add manifests-aws/prometheus-alerts.yaml

# Or stage all changes
git add .

# Commit with message
git commit -m "feat(monitoring): add Prometheus alert rules

Added 5 alert rules for critical infrastructure events:
- NodeDown: Node unavailable for 5 minutes
- PodCrashLooping: Pod restart count > 5
- HighMemoryUsage: Memory > 90%
- HighCPUUsage: CPU > 80%
- PVCAlmostFull: Disk usage > 85%

Alerts route to #alerts Slack channel.

Refs #78"
```

### 4. Push and Create PR

```bash
# Push to remote
git push origin feature/add-prometheus-alerts

# If first push
git push -u origin feature/add-prometheus-alerts
```

Then create Pull Request on GitHub/GitLab with:
- **Title**: Same as commit subject
- **Description**: Explain changes, testing, screenshots
- **Reviewers**: Tag infrastructure team
- **Labels**: `enhancement`, `monitoring`

### 5. After Merge

```bash
# Switch to main
git checkout main

# Pull merged changes
git pull origin main

# Delete local branch
git branch -d feature/add-prometheus-alerts

# Delete remote branch (if not auto-deleted)
git push origin --delete feature/add-prometheus-alerts
```

---

## ✅ Best Practices

### 1. Commit Frequently

✅ **DO**: Commit every logical change  
❌ **DON'T**: Make one huge commit at the end

```bash
# Good: 5 commits
git commit -m "feat(app): add health check endpoint"
git commit -m "feat(k8s): add liveness probe"
git commit -m "feat(k8s): add readiness probe"
git commit -m "docs: update deployment guide"
git commit -m "test: add probe validation script"

# Bad: 1 commit
git commit -m "add probes and docs and tests"
```

### 2. Write Clear Messages

✅ **DO**: Explain what and why  
❌ **DON'T**: Just describe the diff

```bash
# Good
git commit -m "fix(hpa): increase stabilization window to 300s

Prevents HPA from scaling down too quickly during traffic spikes.
Observed pod churn with 60s window causing connection drops.
New value aligns with our 5-minute traffic pattern."

# Bad
git commit -m "fix hpa"
git commit -m "changed number from 60 to 300"
```

### 3. Keep Commits Atomic

✅ **DO**: One logical change per commit  
❌ **DON'T**: Mix unrelated changes

```bash
# Good: Separate commits
git add manifests-aws/hpa.yaml
git commit -m "fix(hpa): increase CPU threshold to 70%"

git add docs/QUICKSTART-AWS.md
git commit -m "docs: add HPA tuning section"

# Bad: Mixed commit
git add manifests-aws/hpa.yaml docs/QUICKSTART-AWS.md
git commit -m "update HPA and docs"
```

### 4. Review Before Pushing

```bash
# Check what you're committing
git status
git diff --staged

# Review commit history
git log --oneline -5

# Amend last commit if needed (before push!)
git commit --amend
```

### 5. Never Commit Secrets

```bash
# Check for secrets before commit
grep -r "password\|secret\|key" manifests-aws/

# Use environment variables instead
# Bad
password: "my-secret-123"

# Good
valueFrom:
  secretKeyRef:
    name: pg-credentials
    key: password
```

---

## 🛡️ Pre-Commit Checks

### Manual Checks

Before every commit, run:

```bash
# 1. Validate YAML syntax
yamllint manifests-aws/*.yaml

# 2. Check for secrets
git diff --cached | grep -i "password\|secret\|key\|token"

# 3. Validate Kubernetes manifests
kubectl apply --dry-run=client -f manifests-aws/

# 4. Run tests
./test-zero-trust.sh
```

### Automated Pre-Commit Hook (Optional)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."

# Check for secrets
echo "Checking for secrets..."
if git diff --cached | grep -iE "(password|secret|aws_access_key|private_key)" | grep -v ".gitignore"; then
    echo "❌ ERROR: Possible secret detected in commit"
    echo "Please remove secrets and use Kubernetes Secrets instead"
    exit 1
fi

# Validate YAML
echo "Validating YAML syntax..."
for file in $(git diff --cached --name-only | grep -E '\.(yaml|yml)$'); do
    if ! yamllint "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: YAML validation failed for $file"
        exit 1
    fi
done

# Validate Kubernetes manifests
echo "Validating Kubernetes manifests..."
for file in $(git diff --cached --name-only | grep "manifests-aws/.*\.yaml"); do
    if ! kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: Kubernetes validation failed for $file"
        exit 1
    fi
done

echo "✅ All pre-commit checks passed!"
```

Make executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## 📊 Git Commands Cheatsheet

### Essential Commands

```bash
# Status and diffs
git status                    # Show working tree status
git diff                      # Show unstaged changes
git diff --staged             # Show staged changes
git log --oneline -10         # Show last 10 commits

# Branching
git branch                    # List branches
git checkout -b feature/name  # Create and switch to branch
git branch -d feature/name    # Delete local branch

# Committing
git add file.yaml             # Stage file
git commit -m "message"       # Commit staged changes
git commit --amend            # Modify last commit

# Remote operations
git pull origin main          # Fetch and merge from main
git push origin branch-name   # Push branch to remote
git fetch origin              # Download remote changes

# Undoing changes
git checkout -- file.yaml     # Discard working changes
git reset HEAD file.yaml      # Unstage file
git revert commit-hash        # Create revert commit
git reset --hard HEAD~1       # Delete last commit (dangerous!)

# History
git log --graph --oneline     # Visual commit history
git blame file.yaml           # Show who changed each line
git show commit-hash          # Show commit details
```

### Advanced Commands

```bash
# Interactive rebase (clean up history before PR)
git rebase -i main

# Cherry-pick specific commit
git cherry-pick commit-hash

# Stash temporary changes
git stash
git stash pop

# Search commits
git log --grep="HPA"
git log --author="name"

# Find when bug was introduced
git bisect start
```

---

## 🎓 Learning Resources

### Books
- **"Infrastructure as Code"** by Kief Morris (this project's foundation)
- **"Pro Git"** by Scott Chacon (free at git-scm.com)

### Online
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Git Documentation](https://git-scm.com/doc)

---

## 🤝 Getting Help

### Common Issues

**Problem**: Merge conflict  
**Solution**: `git status` → edit files → `git add` → `git commit`

**Problem**: Committed to wrong branch  
**Solution**: `git cherry-pick commit-hash` on correct branch, then `git reset --hard HEAD~1` on wrong branch

**Problem**: Need to undo last commit  
**Solution**: `git reset --soft HEAD~1` (keeps changes) or `git reset --hard HEAD~1` (deletes changes)

**Problem**: Forgot to add file to commit  
**Solution**: `git add file` → `git commit --amend --no-edit`

---

## 📋 Summary

### Key Principles

1. **Commit early, commit often** - Small, frequent commits
2. **Write meaningful messages** - Future you will thank you
3. **Never commit secrets** - Use .gitignore and Secrets
4. **Review before pushing** - Check diffs and status
5. **Keep branches short-lived** - Merge within days

### Quick Reference

```bash
# Daily workflow
git checkout main && git pull          # Start day
git checkout -b feature/my-work        # New branch
# ... make changes ...
git add . && git commit -m "..."       # Commit
git push -u origin feature/my-work     # Push
# ... create PR, get review, merge ...
git checkout main && git pull          # End day
git branch -d feature/my-work          # Cleanup
```

---

**Last Updated**: November 3, 2024  
**Version**: 1.0.0  
**Chapter Reference**: Infrastructure as Code, Chapter 4 (Pages 37-41)
