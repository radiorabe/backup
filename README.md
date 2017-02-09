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
* Es werden die Pfade `/etc /home /root /srv /usr/local /var/log /var/local /var/spool /var/backup` mit rsync gesichert. 
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
	19:04:52 Info:     check_backupserver(): backup.vm-admin.int.rabe.ch found and reachable
	19:04:52 Info:     Starting backup now and logging to /tmp/tmp.z8M3EMSlIp
	19:04:55 Success:  Backup successfully finished!
	[root@vm-0011 ~]#

### systemd timer

	# run daily at midnight with 30 minute spread
	systemctl enable rabe-fs-backup.timer

You can change the timer to anything from [systemd.time Calendar Events](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events) it
is configured with `RandomizedDelaySec=30min` to help spread out the load on the server. You can override these settings as follows.

	mkdir -p /etc/systemd/system/rabe-fs-backup.d/
	cat > /etc/systemd/system/rabe-fs-backup.d/override.conf <<EOD
	[Timer]
	# reset repeatable element OnCalendar
	OnCalendar=
	# time you want this to run at
	OnCalendar=06:00
	# may it run exact at the specified time without any spreading
	RandomizedDelaySec=0
	EOD

## RPM Package

This script is available as an RPM package for CentOS 7. We provide a pre-built version
through the [openSUSE Build Server](https://build.opensuse.org/) as part of 
the [home:radiorabe:backup Subproject](https://build.opensuse.org/project/show/home:radiorabe:backup). You can install it as follows.

```bash
curl -o /etc/yum.repos.d/home:radiorabe:backup.repo \
     http://download.opensuse.org/repositories/home:/radiorabe:/backup/CentOS_7/home:radiorabe:backup.repo

yum install rabe-backup
```

## Releasing

New RPMs get built for all tags with a valid version. New releases are created through git.

* Bump the version in rabe-backup.spec and add a new commit to master with the version bump
* Tag this commit with the same version you used in the specfile
* Push master and the tag to github
* The openSUSE Build Service should get triggered and build a new package automagically

## License

Radio RaBe Backup process and automation scripts is released under the terms of the
GNU Affero General Public License.
Copyright 2016 Radio RaBe.
See `LICENSE` for further information.
