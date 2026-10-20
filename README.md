# RaBe Backup

Radio RaBe Backup process and automation scripts.

## System Context

* The **backup script** collects the data from the target system (VM or share).
* The data is stored on the **BTRFS file system** in a revision-proof way.
* The backup server offers the possibility of **self-restore** via NFS or Samba.

## Concepts

* The backup script is located on the backup server.
* The following directories are included in the backup:
  `/etc /home /root /usr/local /var/log /var/local /var/spool /var/backup` with rsync.
* The script is triggered by cron or a systemd timer.

## Scripts

* **backup-fs-vms.sh**: Backs up the VMs of the new infrastructure.
* **backup-userdata.sh**: Backs up user data (shares).
* **backup-appliances.sh**: Backs up secure gateways, firewalls, and access points.
* **backup-physical-servers.sh**: Backs up the virtualization hosts.
* **backup-all.sh**: Wrapper script for systemd.timer that runs all three backup scripts.

## Setup

As root on the backup server:

	git clone https://github.com/radiorabe/backup
	make install

Create an ssh key:

	mkdir -p /var/lib/backup
	ssh-keygen -t rsa -b 4096 -C "backup@vm-1234" -f /var/lib/backup/id_rsa -N ""

Install the CA certificate of the oVirt Engine:

	cp /path/to/ovirt-engine.pem /etc/pki/ca-trust/source/anchors/ovirt-engine.pem
	update-ca-trust

## Usage

As root:

	systemctl start rabe-backup

or

	/usr/local/bin/backup-all.sh

## License

The Radio RaBe backup process and automation scripts are released under the terms
of the GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
