# Container image update workflow

Renovate is intentionally limited to OpenClaw and Hermes in the two deployment
manifests. It runs weekly before 06:00 UTC on Tuesday and creates draft pull
requests only. It never deploys directly, merges automatically, or receives
cluster, Argo CD, registry, or secret-manager credentials.

The images are deployed as an immutable `tag@sha256:digest` reference. The tag
states the intended release; the digest makes the actual artifact immutable.
Only versioned stable tags are eligible. Rolling (`latest`, `main`) and
prerelease (`alpha`, `beta`, `rc`) tags are excluded by the configured allow
lists.

## First run

The existing application references predate this workflow and do not carry a
recoverable release tag. Treat each initial Renovate draft as a normal
application upgrade, not a cosmetic pinning change. Verify the proposed
release notes and compatibility before merging it.

## Review checklist

1. Confirm the PR changes a versioned stable tag and its digest together.
2. Read upstream release notes and verify required configuration migrations.
3. Ensure GitHub lint and manifest checks pass; review security scanner output.
4. Merge only after approval. Argo CD then reconciles the Git change.
5. Confirm the application Deployment is `Available` and the Argo CD
   Application is `Synced` and `Healthy`.

## Rollback

Revert the merged update commit or PR. Argo CD reconciles the prior immutable
digest, restoring the prior artifact without mutable-tag ambiguity.

## Adding another image

Do not remove the default deny rule. Add a package rule that names the exact
manifest, image, allowed stable-tag expression, owner label, and any required
approval behavior. Validate its first draft PR before leaving it enabled.
