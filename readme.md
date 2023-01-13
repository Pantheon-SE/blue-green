# Blue Green Deployment Guide

This GitHub Action workflow is used to synchronize code, database, and files between two Pantheon sites. This workflow can be implemented as part of a Blue/Green deployment workflow. The workflow is triggered when a push is made to the **`main`** branch, but can be configured using other triggers.

The workflow consists of three jobs: sync_code, sync_files, and sync_database

`sync_code`

Sync code will pull down the target repository, add a the source repository as a remote, and then merge the commits from the source repo and branch, then push them to the target repo on the same branch.

`sync_files`

Sync files will mount the source site files directory as a local directory, then sync the files using Rclone (a more performant rsync alternative) to the target files directory.

`sync_database`

Sync database will create an export of the source database on Pantheon, download the compressed files, and then import that into the destination database.

---

All jobs start by running the **`configure-pantheon`** action (located in the **`.github/actions`** directory) to configure the environment to connect to Pantheon sites. This action requires a few variables to work, associated with a user account on Pantheon:

- `PANTHEON_MACHINE_TOKEN` - A [machine token](https://dashboard.pantheon.io/personal-settings/machine-tokens) generated through the Pantheon dashboard
- `PANTHEON_PRIVATE_SSH_KEY` - A Private SSH key (not public) that is generated in the PEM format. See below for more details.
- `PANTHEON_BLUE_SITE_ID` - The UUID or machine name of the source site.
- `PANTHEON_BLUE_SITE_ENV` - The environment name for the source data (files and database).
- `PANTHEON_GREEN_SITE_ID` - The UUID or machine name of the destination site.
- `PANTHEON_GREEN_SITE_ENV` - The environment name for the target data (files and database).

## Caveats

For sites with large file directories, if using the default runner in GitHub Actions, you may run into a timeout during the sync_files job. This just has to do with the limited memory resources available within the CI container. Once an initial sync has completed, subsequent sync jobs for files will go much quicker as only the difference between source and destination will be moved.

## FAQ

**PANTHEON_SSH_KEY**
This private key will need to be generated in a PEM format, as the standard OpenSSH format has some issues in the build containers. Pantheon does not support ed25519 keys yet, so you must use an RSA key in the meantime.

```
ssh-keygen -m PEM -t rsa -f ~/.ssh/id_rsa
```
