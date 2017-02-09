# spec file for package rabe-backup
#
# This file is part of `Radio RaBe Backup process and automation scripts`
#
# Copyright (c) 2016 - 2017 Radio Bern RaBe
#                           http://www.rabe.ch
#
# https://github.com/radiorabe/backup
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Please submit enhancements, bugfixes or comments via GitHub:
# https://github.com/radiorabe/backup
#

%define _repo_name backup
%define _prog_name rabe-fs-backup

Name:          rabe-backup
Version:       0.0.0
Release:       0
Summary:       RaBe Backup process and automation scripts
License:       AGPLv3
Source:        %{name}-%{version}.tar.gz

BuildArch:     noarch

BuildRequires: make

Requires:      rsync
Requires:      openssh-clients

%description
Radio RaBe Backup process and automation scripts.

%prep
%setup -q -n %{_repo_name}-%{version}

%build
make -j2

%install
make install PREFIX=%{buildroot} ETCDIR=%{buildroot}%{_sysconfdir}/%{_prog_name}

%files
%doc LICENSE README.md
%config %{_sysconfdir}/%{_prog_name}/%{_prog_name}.conf
%defattr(-,root,root,0755)
/bin/%{_prog_name}.sh
