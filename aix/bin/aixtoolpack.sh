#!/bin/sh

EXIT_NO_SPACE_VAR=81
EXIT_NO_SPACE_OPT=82
EXIT_NO_RPM=83
EXIT_NO_WGET=84
EXIT_NO_PUPPET=85

### Check there is enough disk space
VARSPACE=`df -m /var/tmp |grep var | awk '{ print $3 }'`
[ $VARSPACE -lt 150 ] && echo "Need at least 150M free in /var/tmp." && exit $EXIT_NO_SPACE_VAR
OPTSPACE=`df -m /opt |grep opt | awk '{ print $3 }'`
[ $OPTSPACE -lt 600 ] && echo "Need at least 600M free in /opt." && exit $EXIT_NO_SPACE_OPT

### Check if needed commands exist
RPM="/usr/bin/rpm"
[ -x $RPM ]  && echo "Found $RPM"  || (echo "Need $RPM" && exit $EXIT_NO_RPM)
WGET="/opt/freeware/bin/wget"
[ -x $WGET ] && echo "Found $WGET" || (echo "Need $WGET" && exit $EXIT_NO_WGET)
[ ! -d /usr/local/bin ] && mkdir -p /usr/local/bin
AYI="/usr/local/bin/ayi.pl"
[ -x $AYI ]  && echo "Found $AYI"  || ($WGET -nv "http://ral-satprd01.gpi.com/git/gitweb.cgi?p=sa-tools.git;a=blob_plain;f=bin/ayi.pl;hb=HEAD" -O $AYI && chmod 755 $AYI)

### Install all the RPMs
#   (first remove some duplicates that cause dependencies issues)
#$RPM -e openldap db sudo
[ `$RPM -q xft` ] && $RPM -e --nodeps xft
[ `$RPM -q xrender` ] && $RPM -e --nodeps xrender
echo "Updating library dependencies. [Pre-install]"
/usr/sbin/updtvpkg
for package in top lsof sudo git ruby; do
    $AYI -y -q -p $package 
    /usr/bin/rm -Rf /var/tmp/RPM
done
echo "Updating library dependencies. [Post-install]"
/usr/sbin/updtvpkg

### Post-install sudo config
[ ! -d /etc/sudoers.d ] && mkdir /etc/sudoers.d
cp /etc/sudoers /etc/sudoers.`date +%Y%m%d-%H%M`
cp /etc/sudoers.rpmnew /etc/sudoers
echo "%sysadmin ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
echo "#includedir /etc/sudoers.d" >>/etc/sudoers

### Install Puppet
echo "Installing Puppet..."
PUPPET="/opt/freeware/bin/puppet"
[ -x $PUPPET ] && echo "Looks like $PUPPET is already installed..." && exit
[ $LIBPATH ] && LIBPATH=/opt/freeware/lib:$LIBPATH
/opt/freeware/bin/gem install puppet hiera
PUPPET="/opt/freeware/bin/puppet"
[ -x $PUPPET ] && echo "Found $PUPPET" || (echo "Need $PUPPET" && exit $EXIT_NO_PUPPET)
/usr/bin/mkssys -s puppet -p $PUPPET -a 'agent --server=ral-pupmstr01.gpi.com' -u 0 -S -n 15 -f 9 -Q -G local
/usr/sbin/mkitab 'puppet:2:once:/usr/bin/startsrc -e "LIBPATH=" -s puppet'
$PUPPET agent --test --server=ral-pupmstr01.gpi.com
#startsrc -s puppet

