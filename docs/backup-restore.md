# Backup and Restore on a Cloudstead

## Backup

There are two scripts that handle backups:

* backup.sh - creates a backup in /var/cloudos/backup
* sync.sh   - copies the backup to S3

backup.sh runs the "backup" recipe for each installed app that is active in the current solo.json run list.

The nightly cron job on a cloudos instance runs the backup_cloudos.sh script, which runs both of the above commands
and logs output /var/log/cloudos_backup.log

## Restore

To restore, run restore.sh. Your environment must contain the following variables:

* AWS_ACCESS_KEY_ID -- the S3 access key
* AWS_SECRET_ACCESS_KEY -- the S3 secret key
* AWS_IAM_USER -- the IAM user name, this is the folder within the S3 bucket that the user has access to
* S3_BUCKET -- the S3 bucket that hold the backups
* BACKUP_KEY -- path to a file containing the encryption key, or the key itself. This is the contents of the /etc/.cloudos file from the original system (the one you backed up that you want to restore)
