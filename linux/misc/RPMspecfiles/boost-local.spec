%define _prefix       /usr/local
%define _bindir       /usr/local/bin
%define _sysconf      /usr/local/etc
%define _datadir      /usr/local/share
%define _includedir   /usr/local/include
%define _mandir       /usr/local/share/man
%define _libdir       /usr/local/lib

Name:           boost-local
Version:        VERSION
Release:        1%{?dist}
Summary:        The Boost C++ headers and shared development libraries

Group:          System Environment/Libraries
License:        Boost
URL:            http://www.boost.org/
Source0:        boost-local.tar.gz

BuildRoot:      %{_tmppath}/boost-local-root-%(%{__id_u} -n)
Prefix:         /usr/local
Packager:       CarQuest SA Team <SYSAdmin@carquest.com>

BuildRequires:  gcc-c++
BuildRequires:  libstdc++-devel
BuildRequires:  bzip2-libs
BuildRequires:  bzip2-devel
BuildRequires:  zlib-devel
BuildRequires:  python
BuildRequires:  python-libs
BuildRequires:  python-devel
BuildRequires:  libicu-devel
Requires:   bzip2
Requires:   python-libs

%description
Boost provides free peer-reviewed portable C++ source libraries.  The
emphasis is on libraries which work well with the C++ Standard
Library, in the hopes of establishing "existing practice" for
extensions and providing reference implementations so that the Boost
libraries are suitable for eventual standardization. (Some of the
libraries have already been proposed for inclusion in the C++
Standards Committee's upcoming C++ Standard Library Technical Report.)

%prep
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
mkdir -p ${RPM_BUILD_ROOT}%{_includedir}/boost ${RPM_BUILD_ROOT}%{_libdir}

%setup -q -n boost-local

%build
BOOST_ROOT=`pwd`
export BOOST_ROOT
./bootstrap.sh --prefix=%{_prefix}

%install
#For some reason, need to do this twice or include dir won't be there...
./b2 --prefix=${RPM_BUILD_ROOT}%{_prefix} --without-mpi link=static variant=release install
./b2 --prefix=${RPM_BUILD_ROOT}%{_prefix} --without-mpi link=static variant=release install

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%defattr(644, root, root, 755)
%{_libdir}/libboost_*
%{_includedir}/boost/*

