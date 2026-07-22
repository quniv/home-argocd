# Container image update workflow

Renovate scans the repository's Argo CD Applications, Kubernetes manifests
under `manifests/` and `bootstrap/`, and Helm values files. This covers Argo CD
Helm chart target revisions and pinned container image references, including
OpenClaw, Hermes, infrastructure images, Velero, and PostgreSQL. It runs weekly
before 06:00 UTC on Tuesday and creates draft pull requests only. It never
deploys directly, merges automatically, or receives cluster, Argo CD, registry,
or secret-manager credentials.

The images are deployed as an immutable `tag@sha256:digest` reference. The tag
states the intended release; the digest makes the actual artifact immutable.
OpenClaw and Hermes have explicit stable-tag rules because both use
calendar-style releases. Other pinned image and Helm references use Renovate's
standard datasource/version handling. Mutable references should be replaced by
an explicit version and digest before relying on automated updates.

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

Add a package rule only when an image needs special handling (for example a
nonstandard version format, a prerelease policy, or a separate ownership
label). Validate the first draft PR for any newly added source before merging.
