# RaBe Backup

Radio RaBe Backup process and automation scripts.

## System Context

* Das **Backupper Script** holt die Daten vom Zielsystem (vm oder share) ab.
* Die Daten werden auf dem **BTRFS Filesystem** revisionssicher abgelegt.
* Auf dem Backup Server wird die Möglichkeit zum **Self-Restore** mittels NFS
  oder Samba Service angeboten.

## Concepts

* Das Backup Script liegt auf dem Backup-Server.
* Es werden die Pfade `/etc /home /root /usr/local /var/log /var/local
  /var/spool /var/backup` mit rsync gesichert.
* Das Script wird von cron oder systemd timer getriggert.

## Setup

As root on the backup server:

	su - backup
	git clone https://github.com/radiorabe/backup

## Usage

As root:

	/home/backup/backup/backup-fs-vms.sh

## RPM Packaging

Since it is not finished yet, I parked packaging files (-see
[README.md](https://github.com/radiorabe/backup/blob/legacy/README.md)) in the
branch [legacy](https://github.com/radiorabe/backup/blob/legacy).

## License

Radio RaBe Backup process and automation scripts is released under the terms of the
GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
