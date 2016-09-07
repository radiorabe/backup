# RaBe Backup

Radio RaBe Backup process and automation scripts.

## System Context

### Client VM

* **Backupper Script**: welches die zu sichernden Daten synchronisiert.

### Backup Server

* **BTRFS Filesystem**: das die gesicherten Daten vorhält und Revisionssicherheit
  gewährleistet.
* **Self-Restore**: Auf dem Backup Server ist ein NFS Service, der dem Nutzer Zugriff
  auf seine Sicherungen gibt.

## Concepts

* Auf jeder Client VM liegt das `backup.sh` Script.
* Es werden die Pfade `/etc /home /root /srv /usr/local /var/log /var/local /var/spool /var/backup` mit rsync gesichert
  gesichert. 
* Weitere zu sichernde Pfade werden in die Datei `/etc/rabe-fs-backup/rabe-fs-backup.conf` eingetragen.
* Weitere **nicht** zu sichernde Pfade werden in die Datei `/etc/rabe-fs-backup/rabe-fs-backup.conf`
  eingetragen.
* Das Script läuft mittels cron und pro VM.
* Um Überlast auf dem Backup Server zu vermeiden, wird der Backup mit einer zufälligen
  anzahl Sekunden verzögert ausgeführt. 

## Setup

### Backup Client

As root:

	mkdir /etc/rabe-fs-backup
	touch /etc/rabe-fs-backup/rabe-fs-backup.conf
	echo "BACKUP_SRV=backup.domain.tld" >/etc/rabe-fs-backup/rabe-fs-backup.conf

Generate a ssh key pair without passphrase:

	ssh-keygen
	Generating public/private rsa key pair.
	Enter file in which to save the key (/root/.ssh/id_rsa)

### Backup Server

As root:

	mkdir /export/remote-backup/hosts/${hostname-of-backup-client}
	cat ${authorized-key-backup-cient} >>~/.ssh/authorized_keys

## Usage

	[root@vm-0011 ~]# /usr/local/bin/rabe-fs-backup.sh
	19:04:52 Notice:   backup_filesystems(): Dirs to backup /etc /home /root /srv /usr/local /var/log /var/local /var/spool /var/backup
	19:04:52 Info:     check_backupserver(): backup.***REMOVED*** found and reachable
	19:04:52 Info:     Starting backup now and logging to /tmp/tmp.z8M3EMSlIp
	19:04:55 Success:  Backup successfully finished!
	[root@vm-0011 backup]#
[root@vm-0011 ~]#

## License

Radio RaBe Backup process and automation scripts is released under the terms of the
GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
