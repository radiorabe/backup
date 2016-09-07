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
* Es werden die Pfade `/` und `/boot` mit der rsync option `--one-file-system`
  gesichert. 
* Weitere zu sichernde Pfade werden in die Datei `/etc/backup.include` eingetragen.
* Weitere **nicht** zu sichernde Pfade werden in die Datei `/etc/backup.exclude`
  eingetragen.
* Das Script läuft mittels cron und pro VM.
* Um Überlast auf dem Backup Server zu vermeiden, wird der Backup mit einer zufälligen
  anzahl Sekunden verzögert ausgeführt. 

## Setup

	mkdir /etc/rabe-fs-backup
	touch /etc/rabe-fs-backup/rabe-fs-backup.conf
	echo "BACKUP_SRV=backup.domain.tld" >/etc/rabe-fs-backup/rabe-fs-backup.conf

## License

Radio RaBe Backup process and automation scripts is released under the terms of the
GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
