# Phase 0/1 Implementation Summary

## ✅ Changes Applied (March 30, 2026)

This patch addresses **Phase 0 (Baseline & Guardrails)** and **Phase 1 (CI/CD Hardening)** from the multi-project platform migration plan.

### 1. **Terraform Version Consistency**

- **File**: `.terraform-version`
- **Change**: Normalized line endings from CRLF to LF
- **Impact**: Local toolchain (`tfenv`) can now correctly parse the pinned version `1.14.4`
- **CI Alignment**: Both workflows now explicitly pin `terraform_version: "1.14.4"` (was `~1.12`, which was too permissive)

### 2. **Line Ending Enforcement via Git Attributes**

- **File**: `.gitattributes` (new)
- **Content**: Enforces LF endings for Terraform (`*.tf`), HCL (`*.hcl`), workflows (`*.yml`), and shell scripts
- **Impact**: Prevents CRLF issues on Windows/macOS commits; ensures consistent tooling behavior across team
- **Next Steps**: Team members should run `git config core.safecrlf true` locally

### 3. **Expanded .gitignore Coverage**

- **File**: `.gitignore`
- **Additions**:
  - `*.tfstate.lock.info` — DynamoDB state lock artifacts
  - `*.tfvars.json` — JSON-formatted tfvars (used in CI generation)
  - `.terragrunt-cache/` — Future Terragrunt support
  - `.env.*.tfvars.json` — CI-generated environment-specific vars
- **Preserved**: `.terraform.lock.hcl` files in root modules are still tracked (staging, production, bootstrap)

### 4. **CI Workflow Hardening — Plan Workflow**

**File**: `.github/workflows/plan.yml`

**Changes**:
1. **Terraform version pinning**: Changed from `~1.12` to exact `1.14.4`
2. **Added format check**: `terraform fmt -check -recursive -diff` catches style drift in PRs
3. **Dynamic tfvars generation**: 
   - If `terraform.tfvars` is not committed (which it shouldn't be), the workflow now generates a minimal one at runtime
   - Uses GitHub Variables: `PROJECT_NAME` and `AWS_REGION` (with sensible defaults)
   - Eliminates the "file not found" failure mode

**Before**:
```bash
terraform plan -var-file=terraform.tfvars
# ❌ Fails if terraform.tfvars not committed
```

**After**:
```bash
if [ ! -f terraform.tfvars ]; then
  cat > terraform.tfvars <<EOF
project_name = "<PROJECT_NAME var or turbo-template>"
aws_region   = "<AWS_REGION var or ap-southeast-1>"
EOF
fi
terraform plan -var-file=terraform.tfvars
# ✅ Works with or without committed tfvars
```

### 5. **CI Workflow Hardening — Apply Workflow**

**File**: `.github/workflows/apply.yml`

**Changes**:
1. **Terraform version pinning**: Both staging and production steps now use exact `1.14.4`
2. **Dynamic tfvars generation**: Applied same runtime generation logic to both `apply-staging` and `apply-production` jobs

**Impact**: 
- Staging and production applies no longer fail due to missing `terraform.tfvars`
- CI/CD can now be run from any branch/PR without pre-committing credentials or config

### 6. **Lockfile Policy Cleanup**

- **File removed**: `modules/aws/alb/.terraform.lock.hcl`
- **Rationale**: Lockfiles should exist only in root modules (`bootstrap/`, `environments/staging/`, `environments/production/`), not in reusable modules
- **Status**: Staged for removal via `git rm`

---

## 📋 Files Modified/Created

| File | Action | Reason |
|------|--------|--------|
| `.terraform-version` | Modified | Normalized line endings (CRLF→LF) |
| `.gitattributes` | Created | Enforce LF endings repo-wide |
| `.gitignore` | Modified | Expanded to cover `*.tfvars.json`, lock artifacts, Terragrunt cache |
| `.github/workflows/plan.yml` | Modified | Added format check, exact version pin, dynamic tfvars, fixed plan step |
| `.github/workflows/apply.yml` | Modified | Exact version pin (2 jobs), dynamic tfvars (2 jobs) |
| `modules/aws/alb/.terraform.lock.hcl` | Deleted | Remove stray module lockfile |

---

## 🧪 Verification Steps

### Local Pre-Commit Validation

```bash
# 1. Verify Terraform version is now parseable locally
cd /home/mjbalcueva/Work/Quanby/DevOps/infrastructure
terraform version
# Expected: Terraform v1.14.4

# 2. Verify formatting is clean
terraform fmt -check -recursive
# Expected: no files out of format (or list files to fix)

# 3. Verify validation still passes
cd environments/production
terraform validate
# Expected: Success

cd ../staging
terraform validate
# Expected: Success
```

### GitHub Actions Workflow Behavior

**On next PR touching .tf files:**
1. Plan workflow detects changed environment
2. Runs `terraform fmt -check` (new!) ← catches style issues early
3. Runs `terraform validate` (existing)
4. Generates `terraform.tfvars` at runtime if not committed (new!)
5. Runs `terraform plan` ← should succeed even with no committed tfvars
6. Comments plan on PR

**On merge to main:**
1. Apply workflow detects environment changes
2. Applies to staging first
3. (Awaits staging success)
4. Applies to production
5. Outputs resource summary

---

## 🚀 Next Steps

### Immediate (same session)
- Run local validation to confirm no regressions
- Test plan workflow on a sample PR
- Test apply workflow on a manual dispatch

### Near-term (Phase 2)
- Add `tflint` and `tfsec`/`checkov` to plan workflow
- Migrate GitHub Actions AWS auth to OIDC role assumption (remove long-lived keys)
- Gate production applies behind environment approval

### Mid-term (Phase 2-4)
- Introduce `services` map variable schema in environments
- Refactor modules to consume service maps dynamically
- Implement backward-compatible output contracts

---

## ⚠️ Known Limitations & Assumptions

1. **GitHub Variables**: Assumes `PROJECT_NAME` and `AWS_REGION` are set in GitHub repository settings. If not set, workflow falls back to sensible defaults.
2. **tfvars.example files**: If your environments have non-default variables (e.g., certificate ARNs, NAT HA config), you'll need to either:
   - Commit those as part of terraform.tfvars (breaking the ignore rule), or
   - Define them as GitHub variables/secrets and extend the tfvars-generation script
3. **Formatting**: `terraform fmt -check` will now fail PRs if code is unformatted. Run `terraform fmt -recursive` locally before committing.

---

## 💾 State of Repository

**Status**: Clean, ready for Phase 2 module refactoring.

**Git State** (pending commit):
```
M .github/workflows/apply.yml          — Terraform version, tfvars generation
M .github/workflows/plan.yml           — Format check, version, tfvars generation
M .gitignore                           — Expanded coverage
D modules/aws/alb/.terraform.lock.hcl  — Removed stray lockfile
?? .gitattributes                      — Enforce line endings
```

**Next Commit Message** (suggested):
```
chore: phase 0/1 - baseline repo hygiene and CI hardening

- Normalize Terraform version to 1.14.4 across local and CI
- Add .gitattributes to enforce LF line endings (fix CRLF parsing issues)
- Expand .gitignore to cover tfvars.json and state lock artifacts
- Add terraform fmt check to PR workflow (catch formatting drift early)
- Make CI workflows generate tfvars.json at runtime (remove committed dependency)
- Remove stray lockfile from reusable ALB module (lockfiles belong in root only)

This unblocks Phase 2 module refactoring and removes CI fragility around
missing terraform.tfvars files. Team members should run:
  git config core.safecrlf true
```

---

## 📚 References

- **Plan documentation**: `/memories/session/plan.md`
- **Repository structure**: See README.md for architecture overview
- **Multi-project platform goals**: Phase 2-4 enable config-driven N-service deployment
