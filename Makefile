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

PN		= rabe-fs-backup

#PREFIX		?= /usr/local
PREFIX		?= .
BINDIR		= $(PREFIX)/bin
ETCDIR		?= $(PREFIX)/etc
DOCDIR		= $(PREFIX)/share/doc/$(PN)
MAN1DIR		= $(PREFIX)/share/man/man1

all:

test:
	@echo Testing script syntax...
	bash -n $(PREFIX)/$(PN).sh
	@echo done.

clean:
	@echo Cleaning up files...
	find $(BINDIR)/ -name "*.sh" -delete
	@echo done.

install-bin:
	@echo 'installing main script...'
	install -Dm755 $(PN).sh "$(BINDIR)/$(PN).sh"
	install -Dm755 config/$(PN).conf "$(ETCDIR)/$(PN).conf"

install-man:

install-doc:

install: all install-bin install-man install-doc
