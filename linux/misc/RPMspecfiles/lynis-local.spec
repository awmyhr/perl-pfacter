%define _prefix       /usr/local
%define _bindir       /usr/local/bin
%define _sysconf      /usr/local/etc
%define _datadir      /usr/local/share
%define _includedir   /usr/local/include
%define _mandir       /usr/local/share/man
%define _pluginsdir   /usr/local/share/lynis/plugins
%define _dbdir        /usr/local/share/lynis/db
%define _docdir       /usr/local/share/doc

Name:                   lynis
Version:                VERSION
Release:                1
Summary:                Security and system auditing tool.

Group:                  Applications/System
License:                GPL
URL:                    http://cisofy.com/
Source:                 lynis-local.tar.gz
Vendor:                 CISOfy / Michael Boelen

BuildRoot:              %{_tmppath}/lynis-local-root-%(%{__id_u} -n)
BuildArch:              noarch
Prefix:                 /usr/local
Packager:               CarQuest SA Team <SYSAdmin@carquest.com>

%description
Lynis is a security tool to audit and harden Unix/Linux based systems. It scans a
system and provides the user with suggestion and warnings regarding taken security
measures. Examples include:
     - Security enhancements
     - Logging and auditing options
     - Banner identification
     - Software availability
     - Missing security patches

Lynis is released as a GPLv3 licensed project and free for everyone to use.

See http://cisofy.com for a full description and documentation.

%prep
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
mkdir -p $RPM_BUILD_ROOT

%setup -q -n lynis-local

%build

%install
# Install profile
install -d ${RPM_BUILD_ROOT}%{_sysconf}/lynis
install default.prf ${RPM_BUILD_ROOT}%{_sysconf}/lynis
# Install binary
install -d ${RPM_BUILD_ROOT}%{_bindir}
install lynis ${RPM_BUILD_ROOT}%{_bindir}
# Install man page
install -d ${RPM_BUILD_ROOT}%{_mandir}/man8
install lynis.8 ${RPM_BUILD_ROOT}%{_mandir}/man8
# Install functions/includes
install -d ${RPM_BUILD_ROOT}%{_includedir}/lynis
install include/* ${RPM_BUILD_ROOT}%{_includedir}/lynis
# Install plugins
install -d ${RPM_BUILD_ROOT}%{_pluginsdir}
install plugins/* ${RPM_BUILD_ROOT}%{_pluginsdir}
# Install database files
install -d ${RPM_BUILD_ROOT}%{_dbdir}
install db/* ${RPM_BUILD_ROOT}%{_dbdir}


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(644, root, root, 755)
%attr(755, root, root) %{_bindir}/lynis
%doc CHANGELOG FAQ LICENSE README
%doc %{_mandir}/man8/lynis.8

%{_sysconf}/lynis/default.prf
%{_dbdir}/*
%{_includedir}/lynis/*
%{_pluginsdir}/*

