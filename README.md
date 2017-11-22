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

### systemd timer

```bash
# run daily at midnight with 30 minute spread
systemctl enable rabe-fs-backup.timer
```

You can change the timer to anything from [systemd.time Calendar Events](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events).
It is configured with [`RandomizedDelaySec=30min`](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#RandomizedDelaySec=) to help spread 
out the load on the server. You can override these settings as follows.

```bash
mkdir -p /etc/systemd/system/rabe-fs-backup.d/

cat > /etc/systemd/system/rabe-fs-backup.d/override.conf <<EOD
[Timer]
# reset repeatable element OnCalendar
OnCalendar=
# time you want this to run at
OnCalendar=06:00
# may it run exactly at the specified time without any spreading
RandomizedDelaySec=0
EOD
```

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
