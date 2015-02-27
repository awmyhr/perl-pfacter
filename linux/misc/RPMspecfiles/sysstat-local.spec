%define _prefix       /usr/local
%define _bindir       /usr/local/bin
%define _sysconf      /usr/local/etc
%define _datadir      /usr/local/share
%define _includedir   /usr/local/include
%define _mandir       /usr/local/share/man
%define _localstatedir /usr/local/var

Name:       sysstat-local
Version:    VERSION
Release:    1%{?dist}
Summary:    SAR, SADF, MPSTAT, IOSTAT, NFSIOSTAT-SYSSTAT, CIFSIOSTAT and PIDSTAT for Linux

Group:      Applications/System
License:    GPL
URL:        http://pagesperso-orange.fr/sebastien.godard/
Source0:    sysstat-local.tar.gz

BuildRoot:  %{_tmppath}/sysstat-local-root-%(%{__id_u} -n)
Prefix:     /usr/local
Packager:   CarQuest SA Team <SYSAdmin@carquest.com>

Requires:   gettext

%description
The sysstat package contains the sar, sadf, mpstat, iostat, pidstat,
nfsiostat-sysstat, cifsiostat and sa tools for Linux.
The sar command collects and reports system activity information.
The information collected by sar can be saved in a file in a binary
format for future inspection. The statistics reported by sar concern
I/O transfer rates, paging activity, process-related activities,
interrupts, network activity, memory and swap space utilization, CPU
utilization, kernel activities and TTY statistics, among others. Both
UP and SMP machines are fully supported.
The sadf command may  be used to display data collected by sar in
various formats (CSV, XML, etc.).
The iostat command reports CPU utilization and I/O statistics for disks.
The mpstat command reports global and per-processor statistics.
The pidstat command reports statistics for Linux tasks (processes).
The nfsiostat-sysstat command reports I/O statistics for network filesystems.
The cifsiostat command reports I/O statistics for CIFS filesystems.

%prep
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
mkdir -p $RPM_BUILD_ROOT

%setup -q -n sysstat-local

%build
./configure --prefix=%{_prefix} \
  sa_dir=%{_localstatedir}/log/sa \
  conf_dir=%{_sysconf}/sysstat \
	sa_lib_dir=%{_localstatedir}/log/sa \
  --mandir=%{_mandir} \
	--disable-man-group \
	DESTDIR=$RPM_BUILD_ROOT
make

%install
install -d $RPM_BUILD_ROOT%{_localstatedir}/log/sa
make install

mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/rc.d/init.d
install -m 755  sysstat ${RPM_BUILD_ROOT}%{_sysconf}/rc.d/init.d/sysstat
mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/sysstat
install -m 644 sysstat.sysconfig ${RPM_BUILD_ROOT}%{_sysconf}/sysstat/sysstat
install -m 644 sysstat.ioconf ${RPM_BUILD_ROOT}%{_sysconf}/sysstat/sysstat.ioconf
mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/cron.d
install -m 644 cron/sysstat.crond.sample ${RPM_BUILD_ROOT}%{_sysconf}/cron.d/sysstat
mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/rc2.d
cd ${RPM_BUILD_ROOT}%{_sysconf}/rc2.d && ln -sf ../init.d/sysstat S01sysstat
mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/rc3.d
cd ${RPM_BUILD_ROOT}%{_sysconf}/rc3.d && ln -sf ../init.d/sysstat S01sysstat
mkdir -p ${RPM_BUILD_ROOT}%{_sysconf}/rc5.d
cd ${RPM_BUILD_ROOT}%{_sysconf}/rc5.d && ln -sf ../init.d/sysstat S01sysstat

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(644, root, root, 755)
%attr(755,root,root) %{_bindir}/*
%doc %{_datadir}/doc/sysstat-%{version}/*
%{_mandir}/man*/*
%{_datadir}/locale/*/LC_MESSAGES/sysstat.mo

%dir %{_localstatedir}/log/sa
%{_localstatedir}/log/sa/*
%{_sysconf}/sysstat/sysstat
%{_sysconf}/sysstat/sysstat.ioconf
%attr(755,root,root) %{_sysconf}/rc.d/init.d/sysstat
%attr(755,root,root) %{_sysconf}/rc2.d/S01sysstat
%attr(755,root,root) %{_sysconf}/rc3.d/S01sysstat
%attr(755,root,root) %{_sysconf}/rc5.d/S01sysstat
%config(noreplace)   %{_sysconf}/cron.d/sysstat

