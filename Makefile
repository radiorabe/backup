#!/usr/bin/make -f
#
# This file is part of radiorabe backup
# https://github.com/radiorabe/backup
#
# radiorabe backup is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# radiorabe backup is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with radiorabe backup.  If not, see <http://www.gnu.org/licenses/>.

PREFIX		?= /usr
ETCDIR		?= /etc
BINDIR		= $(PREFIX)/local/scripts/backup
LIBDIR		= $(PREFIX)/lib
UNITDIR		= $(LIBDIR)/systemd/system
#DOCDIR		= $(PREFIX)/share/doc/$(PN)
#MAN1DIR        = $(PREFIX)/share/man/man1

all:

test:
	@echo Testing script syntax...
	bash -n backup-appliances.sh
	bash -n backup-fs-vms.sh
	bash -n run-all.sh
	@echo done.

uninstall:
	@echo Cleaning up files...
	rm $(ETCDIR)/btrbk/btrbk.conf
	rm $(UNITDIR)/rabe-backup.service
	rm $(UNITDIR)/rabe-backup.timer
	rm $(BINDIR)/run-all.sh
	rm $(BINDIR)/backup-appliances.sh
	rm $(BINDIR)/backup-fs-vms.sh
	systemctl daemon-reload
	@echo done.

install-bin:
	@echo 'installing main scripts...'
	install -Dm755 backup-appliances.sh "$(BINDIR)/backup-appliances.sh"
	install -Dm755 backup-fs-vms.sh "$(BINDIR)/backup-fs-vms.sh"
	install -Dm755 backup-physical-servers.sh "$(BINDIR)/backup-physical-servers.sh"
	install -Dm755 run-all.sh "$(BINDIR)/run-all.sh"
	@echo 'installing btrbk.conf...'
	install -Dm644 config/btrbk.conf "$(ETCDIR)/btrbk/btrbk.conf"
	@echo 'installing systemd services...'
	install -Dm644 config/rabe-backup.service "$(UNITDIR)/rabe-backup.service"
	install -Dm644 config/rabe-backup.timer "$(UNITDIR)/rabe-backup.timer"
	systemctl daemon-reload
	systemctl start rabe-backup.timer
	systemctl enable rabe-backup.timer
	systemctl enable rabe-backup.service

install-man:

install-doc:

install: all install-bin install-man install-doc
