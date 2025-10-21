# RaBe Backup

Radio RaBe Backup process and automation scripts.

## System Context

* The **Backupper Script** collects the data from the target system (vm or share).
* The data is stored on the **BTRFS file system** in a revision-proof way.
* The backup server offers the possibility of **self-restore** via NFS or Samba service.


## Concepts

* The backup script is located on the backup server.
* The following directories are included in the backup
  `/etc /home /home /root /usr/local /var/log /var/local /var/spool /var/backup` with rsync.
* The script is triggered by cron or systemd timer.

## Scripte

* **backup-fs-vms.sh**: Backup the VMs of the new infrastructure
* **backup-userdata.sh**: Backup user data (shares)
* **backup-appliances.sh**: Backup Secures gateway, firewall and access points.
* **backup-physical-servers.sh**: Backup the virtualization hosts
* **run-all.sh**: Wrapper script for systemd.timer which run all three backup scripts.

## Setup

As root on the backup server:

	git clone https://github.com/radiorabe/backup
	make install

Create a backup user within a ssh key:

	su - backup
	mkdir .ssh
	ssh-keygen -t rsa -b 4098 -C "backup@vm-1001" -f ~/.ssh/id_backup

Install the CA certificate of the oVirt Engine:

	cp /path/to/ovirt-engine.pem /etc/pki/ca-trust/source/anchors/ovirt-engine.pem
	update-ca-trust

## Usage

As root:

	systemctl start rabe-backup

or

	/user/local/scripts/backup/run-all.sh

## RPM Packaging

Since it is not finished yet, I parked packaging files (-see
[README.md](https://github.com/radiorabe/backup/blob/legacy/README.md)) in the
branch [legacy](https://github.com/radiorabe/backup/tree/legacy).

## License

Radio RaBe Backup process and automation scripts is released under the terms of the
GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
