# Operations

Track operational procedures and their status.

## Entry format

Store each operation at `ops-NNN_<procedure-name>/index.md`, such as
`ops-001_database-backup/index.md`.

- Code: The next unused three-digit code, starting with `ops-001`.
- Description: A concise summary of the procedure.
- Status: `in progress`, `completed`, or `on hold`. Use `in progress` for a new
  procedure unless another status is specified.

Add the procedure to this index when creating it. Keep its code, description,
and status synchronized with the operation page.

## Index

| Code | Description | Status |
| --- | --- | --- |
| [ops-001](ops-001_read-only-agent-kubeconfig/index.md) | Create and hand off a short-lived, read-only agent kubeconfig. | in progress |
