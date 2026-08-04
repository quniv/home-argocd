# Container image update workflow

Renovate scans the repository's Argo CD Applications, Kubernetes manifests
under `manifests/` and `bootstrap/`, and Helm values files. This covers Argo CD
Helm chart target revisions and pinned container image references, including
infrastructure images, Velero, and PostgreSQL. It creates a non-draft pull
request as soon as the hosted Renovate job detects an update, without
repository-level schedule, hourly, or concurrency limits. Renovate merges the
pull request after its status checks pass. It never receives cluster, Argo CD,
registry, or secret-manager credentials, but merging to `main` causes Argo CD
to reconcile and deploy the updated reference automatically.

The images are deployed as an immutable `tag@sha256:digest` reference. The tag
states the intended release; the digest makes the actual artifact immutable.
Pinned image and Helm references use Renovate's standard datasource/version
handling. Mutable references should be replaced by an explicit version and
digest before relying on automated updates.

## First run

The existing application references predate this workflow and do not carry a
recoverable release tag. Treat each initial Renovate pull request as a normal
application upgrade, not a cosmetic pinning change. CI is the pre-deployment
gate; add a package rule with `automerge: false` before enabling a dependency
that requires a manual compatibility or migration review.

## Automated flow

1. Renovate detects an eligible update and immediately opens a regular pull
   request.
2. GitHub Actions run the repository's lint and security checks.
3. Renovate waits for reported status checks to pass, then merges the pull
   request. GitHub platform automerge is disabled so GitHub cannot merge it
   before Renovate evaluates the checks.
4. Argo CD reconciles the merged reference automatically.
5. Confirm the application Deployment is `Available` and the Argo CD
   Application is `Synced` and `Healthy`.

## Rollback

Revert the merged update commit or PR. Argo CD reconciles the prior immutable
digest, restoring the prior artifact without mutable-tag ambiguity.

## Adding another image

Add a package rule only when an image needs special handling (for example a
nonstandard version format, a prerelease policy, or a separate ownership
label). Set `automerge: false` in that rule when the dependency requires manual
review before deployment.
