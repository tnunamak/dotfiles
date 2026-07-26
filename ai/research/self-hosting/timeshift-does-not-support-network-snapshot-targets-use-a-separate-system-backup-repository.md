# Timeshift does not support network snapshot targets; use a separate system-backup repository

Date: 2026-07-24

## Decision

Do not configure Timeshift to store snapshots on an NFS or SMB share. Keep a small local Timeshift retention window for fast rollback and use a dedicated network backup repository with a backup tool designed for that role.

## Evidence

- The upstream Timeshift issue tracker states that network backups are not supported and explains that SMB mountpoints are intentionally unsupported ([issue 140](https://github.com/linuxmint/timeshift/issues/140)).
- A current Linux Mint report confirms that even a pre-mounted NFS path is rejected because Timeshift remounts its selected target under `/run/timeshift/backup` ([forum report](https://forums.linuxmint.com/viewtopic.php?t=431484)).
- Timeshift's own documentation defines it as a system restore tool using rsync plus hardlinks and recommends an external non-system *partition*, not a network destination ([Timeshift documentation](https://teejee2008.github.io/timeshift/)).
- Restic supports a local filesystem repository, can back up `/` with `--one-file-system`, and documents restore and xattr behavior. This makes an NFS-mounted, dedicated NAS directory a suitable repository location after NFS permission and filesystem-semantics testing ([backup docs](https://restic.readthedocs.io/en/v0.15.1/040_backup.html), [restore docs](https://restic.readthedocs.io/en/stable/050_restore.html)).

## Recommended Layout

- `Timeshift`: retain two local daily snapshots on the root filesystem for quick rollback.
- `system-backups-peregrine`: a dedicated Synology NFS share, writable only by Peregrine (`192.168.1.4`) with root-preserving access, used by a repository-oriented backup tool.
- Do not grant the client root access to a broad shared backup directory. One host gets one dedicated share.

## Retention Ground Truth

- Timeshift documents daily, weekly, monthly, hourly, and boot levels, but gives no universal count. Its space-pressure guidance is to keep one level selected and set that count to five or fewer ([Timeshift documentation](https://teejee2008.github.io/timeshift/)).
- Synology Hyper Backup's built-in Smart Recycle policy retains daily versions for up to one month, then weekly versions. Its custom policy supports explicit retention periods and intervals ([Synology Hyper Backup settings](https://kb.synology.com/en-uk/DSM/help/HyperBackup/data_backup_settings)).
- Restic formally supports daily, weekly, monthly, and yearly retention selectors. Its documentation gives the GFS-shaped example of seven daily, five weekly, twelve monthly, and seventy-five yearly snapshots; the exact counts are workload and storage policy choices, not a Restic recommendation ([Restic forget documentation](https://restic.readthedocs.io/en/latest/060_forget.html)).
- Community Restic policies vary substantially: examples include 3/4/3/1 for constrained storage and 14/8/12/10 for longer history. The stable principle is tiered retention, not a universal numeric policy ([3/4/3/1 discussion](https://forum.restic.net/t/retention-policy/4953), [14/8/12/10 example](https://handbook.sansi.io/sansi_sdt_handbook.pdf)).

## Restore Consequence

The NAS repository is a durable recovery backup, not a boot-menu rollback. Restoring it requires booting a live environment, mounting the NAS repository, and running the backup tool's restore workflow. Test this with a non-destructive file restore before relying on it.
