%define _prefix     /usr/local

Summary:    HipHop PHP engine
Name:       hhvm-local
Version:    3.1.0
Release:    1%{?dist}
License:    GPLv3
Group:      Applications/Internet
URL:        https://github.com/facebook/hhvm
Source0:    %{name}-%{version}.tar.gz
BuildRoot:  %{_tmppath}/%{name}-%{version}-root-%(%{__id_u} -n)
Prefix:     /usr/local

BuildRequires: git, cpp, make, autoconf, automake, libtool, patch, memcached
BuildRequires: gcc-c++, cmake, wget, expat-devel, binutils-devel, svn
BuildRequires: elfutils-libelf-devel rpmdevtools yum-utils, patch

Requires: libmcrypt-devel, libmemcached-devel, jemalloc-devel, tbb-devel
Requires: libdwarf-devel, mysql-devel, libxml2-devel, libicu-devel
Requires: pcre-devel, gd-devel, sqlite-devel, pam-devel, libcurl-devel
Requires: bzip2-devel, oniguruma-devel, openldap-devel, readline-devel
Requires: libc-client-devel, libcap-devel, libevent-devel, libxslt-devel
Requires: glog-devel, boost-devel, ImageMagick-devel 

%description
HHVM is an open-source virtual machine designed for executing programs written in Hack and PHP. HHVM uses a just-in-time (JIT) compilation approach to achieve superior performance while maintaining the flexibility that PHP developers are accustomed to.

%prep
%setup -q -n %{name}-%{version}

%build
#./configure --prefix=$RPM_BUILD_ROOT%{_prefix} && make
%configure

%install
rm -rf $RPM_BUILD_ROOT

make install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)

%doc AUTHORS COPYING ChangeLog NEWS README
%{_prefix}/bin/*
%{_prefix}/share/man/man*/*

