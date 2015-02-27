%define _prefix       /usr/local
%define _bindir       /usr/local/bin
%define _sysconf      /usr/local/etc
%define _datadir      /usr/local/share
%define _includedir   /usr/local/include
%define _mandir       /usr/local/share/man
%define _docdir       /usr/local/share/doc

Name:       tcpflow-local
Version:    VERSION
Release:    1%{?dist}
Summary:    Network traffic recorder

Group:      Applications/System
License:    GPLv3
URL:        https://github.com/simsong/tcpflow
Source0:    tcpflow-local.tar.gz
BuildRoot:  %{_tmppath}/tcpflow-local-root-%(%{__id_u} -n)
Prefix:     /usr/local
Packager:   CarQuest SA Team <SYSAdmin@carquest.com>

BuildRequires: boost-local
Requires:      boost-local

%description
tcpflow is a program that captures data transmitted as part of TCP connections (flows),
and stores the data in a way that is convenient for protocol analysis or debugging.
A program like 'tcpdump' shows a summary of packets seen on the wire, but usually
doesn't store the data that's actually being transmitted. In contrast, tcpflow
reconstructs the actual data streams and stores each flow in a separate file for later
analysis.

%prep
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
mkdir -p $RPM_BUILD_ROOT

%setup -q -n tcpflow-local

%build
sh bootstrap.sh

MYCFLAGS="-I/usr/local/include $RPM_OPT_FLAGS"
LDFLAGS="-L/usr/local/lib" CFLAGS="$MYCFLAGS" ./configure --prefix=%{_prefix} --localstatedir=%{_localstatedir}/%{_lib}

%install
make
make prefix=$RPM_BUILD_ROOT%{prefix} install

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(644, root, root, 755)
%attr(755,root,root) %{_bindir}/*
%doc AUTHORS COPYING ChangeLog NEWS README.md
%{_mandir}/man*/*

