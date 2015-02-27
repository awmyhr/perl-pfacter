#!/usr/bin/bash

EXIT_RELEASE_NOT_SUPPORTED=81
EXIT_NO_SPACE_OPT=82
EXIT_NO_PKGUTIL=83
EXIT_NO_WGET=84
EXIT_NO_PUPPET=85
ECHO='/usr/bin/echo'

### Check there is enough disk space
OPTSPACE=`/usr/sbin/df -b /opt | /usr/bin/grep dev | /usr/bin/awk '{ print $2 }'`
[ $OPTSPACE -lt 400000 ] && $ECHO 'Need at least 400M free in /opt.' && exit $EXIT_NO_SPACE_OPT

### Need wget before we start, let's look in common locations
PATH=/opt/csw/bin:/usr/local/bin:/usr/bin:/bin:/usr/ccs/bin:/usr/sfw/bin
export PATH
WGET=`which wget`
[ -x $WGET ] && $ECHO "Found $WGET, installing pkgutil" || ($ECHO "Need $WGET" && exit $EXIT_NO_WGET)

### Common commands & flags - make sure we get the version we want
PKGUTIL='/opt/csw/bin/pkgutil'
PKGADD='/usr/sbin/pkgadd -d'
LN='/usr/bin/ln -s'
RM='/usr/bin/rm'
MV='/usr/bin/mv'

### Set release specific variables & install pkgutil
RELEASE=`/usr/bin/uname -r`
if [ $RELEASE == '5.8' ]; then
    MIRROR='mirror=http://mirror.opencsw.org/opencsw/dublin'
    BASEPKG='binutils gnupg'
    PKIHOME=''

    $WGET http://ral-satprd01/sol/pkgutil.pkg
    $PKGADD pkgutil.pkg all
    $RM pkgutil.pkg

elif [ $RELEASE == '5.9' ]; then
    MIRROR='mirror=http://mirror.opencsw.org/opencsw/stable'
    BASEPKG='coreutils cswpki gnupg'
    PKIHOME='--homedir=/var/opt/csw/pki'

    $WGET http://ral-satprd01/sol/pkgutil.pkg
    $PKGADD pkgutil.pkg all
    $RM pkgutil.pkg

elif [ $RELEASE == '5.10' ]; then
    MIRROR='mirror=http://mirror.opencsw.org/opencsw/stable'
    BASEPKG='coreutils cswpki gnupg'
    PKIHOME='--homedir=/var/opt/csw/pki'

    $PKGADD http://get.opencsw.org/now

else
    echo 'Sorry, this release of Solaris is not supported by this script'
    exit $EXIT_RELEASE_NOT_SUPPORTED
fi

###Did we succeed installing pkgutil?
[ -x $PKGUTIL ] && $ECHO "$PKGUTIL installed, installing base packages..." || ($ECHO "Could not install $PKGUTIL" && exit $EXIT_NO_PKGUTIL)
PKGUTIL='/opt/csw/bin/pkgutil -y -i'

###Install base packages
$ECHO $MIRROR >>/etc/opt/csw/pkgutil.conf
$ECHO 'wgetopts=-nv' >>/etc/opt/csw/pkgutil.conf
$PKGUTIL $BASEPKG

###Install repo key
$ECHO 'Installing OpenCSW gpg keys'
if [ $RELEASE == '5.8' ]; then
    $WGET --output-document=/tmp/gpg.key http://ral-satprd01.gpi.com/keys/CSW-GPG-KEY-opencsw
    /opt/csw/bin/gpg --import /tmp/gpg.key
    $RM /tmp/gpg.key
else
    $ECHO 'pki_auto=yes' >> /etc/opt/csw/csw.conf
    $ECHO 'use_md5=true' >> /etc/opt/csw/pkgutil.conf
    /opt/csw/bin/cswpki --import --force
fi

$ECHO 'Select 3, then quit'
/opt/csw/bin/gpg $PKIHOME --edit-key board@opencsw.org trust
#3
#q

###Install the rest of the packages, and set-up some configs
$ECHO 'use_gpg=true' >> /etc/opt/csw/pkgutil.conf
$ECHO 'Installing further packages, and basic configs...'
$PKGUTIL gsed top iftop lsof sudo rsync vim wget gzip git gnupg syslog_ng openssh openssh_client rubygems
$ECHO 'PATH=$PATH:/opt/csw/gnu:/opt/csw/bin' >> /etc/profile
$ECHO 'PATH=/opt/csw/bin:/usr/bin:/bin:/usr/local/bin' >> /etc/default/login
$ECHO 'SUPATH=/opt/csw/sbin:/usr/sbin:/sbin:/usr/local/sbin:/opt/csw/bin:/usr/bin:/bin:/usr/local/bin' >> /etc/default/login
/usr/bin/mkdir -p /etc/puppet /var/lib /etc/syslog-ng
if [ -f /etc/opt/csw/sudoers ]; then
    $MV -f /etc/opt/csw/sudoers /etc/opt/csw/sudoers.`date +%Y%m%d-%H%M`
    $MV -f /etc/opt/csw/sudoers.d /etc/opt/csw/sudoers.d.`date +%Y%m%d-%H%M`
fi
$LN /etc/sudoers /etc/opt/csw/sudoers
$LN /etc/sudoers.d /etc/opt/csw/sudoers.d
$LN /etc/opt/csw/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
if [ -x /usr/lib/ssh/sshd ]; then
    $MV /usr/lib/ssh/sshd /usr/lib/ssh/sshd.orig
    $LN /opt/csw/sbin/sshd /usr/lib/ssh/sshd
fi
if [ -x /usr/bin/ssh ]; then
    $MV /usr/bin/ssh /usr/bin/ssh.orig
    $LN /opt/csw/bin/ssh /usr/bin/ssh
fi
/usr/bin/cp /etc/ssh/*key* /etc/opt/csw/ssh/
$ECHO "%sysadmin ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
$ECHO "#includedir /etc/sudoers.d" >>/etc/sudoers

###Install Puppet
$ECHO 'Installing Puppet...'
GEM='/opt/csw/bin/gem'
[ -x $GEM ] && $GEM install puppet hiera || ($ECHO 'ERROR: RubyGems did not install properly, Puppet not installed')
$LN $GEM /usr/bin/gem

PUPPET="/opt/csw/bin/puppet"
[ -x $PUPPET ] && echo "Found $PUPPET" || (echo "Need $PUPPET" && exit $EXIT_NO_PUPPET)
$PUPPET agent --test --server=ral-pupmstr01.gpi.com

## Change sshd & syslog, enable puppet
if [ $RELEASE == '5.10' ]; then
    SVCADM='/usr/sbin/svcadm'
    $SVCADM disable cswopenssh
    $SVCADM disable ssh && sleep 4
    $SVCADM disable cswsyslog_ng
    $SVCADM disable system-log && sleep 4
    $SVCADM enable cswopenssh
    $SVCADM enable cswsyslog_ng

    /usr/bin/mkdir -p /var/opt/csw/svc/manifest/network
    $WGET --output-document='/var/opt/csw/svc/manifest/network/cswpuppetd.xml' 'http://ral-satprd01.gpi.com/git/gitweb.cgi/?p=sa-tools.git;a=blob_plain;f=etc/solaris_init.d/cswpuppetd.xml;hb=HEAD'
    $WGET --output-document='/etc/opt/csw/init.d/cswpuppetd' 'http://ral-satprd01.gpi.com/git/gitweb.cgi/?p=sa-tools.git;a=blob_plain;f=etc/solaris_init.d/cswpuppetd;hb=HEAD'
    $LN /etc/opt/csw/init.d/cswpuppetd /var/opt/csw/svc/method/svc-cswpuppetd
    /usr/bin/chmod 754 /etc/opt/csw/init.d/cswpuppetd
    /usr/bin/chown root:other /etc/opt/csw/init.d/cswpuppetd
    /usr/sbin/svccfg import /var/opt/csw/svc/manifest/network/cswpuppetd.xml

    $SVCADM enable cswpuppetd
else
    #   syslog-ng does not appear to be working yet on 8/9...
    $MV /etc/rc3.d/S80cswsyslog_ng /etc/rc3.d/s80cswsyslog_ng
    #$MV /etc/rc2.d/S74syslog /etc/rc2.d/s74syslog

    $WGET --output-document='/etc/init.d/cswsshd' 'http://ral-satprd01.gpi.com/git/gitweb.cgi/?p=sa-tools.git;a=blob_plain;f=etc/solaris_init.d/cswsshd;hb=HEAD'
    $MV /etc/rc3.d/S[89]9sshd /etc/rc3.d/s89sshd
    $LN /etc/init.d/cswopenssh  /etc/rc0.d/K99cswopenssh
    $LN /etc/init.d/cswopenssh  /etc/rc1.d/K99cswopenssh
    $LN /etc/init.d/cswopenssh  /etc/rc2.d/K99cswopenssh
    $LN /etc/init.d/cswopenssh  /etc/rc3.d/S99cswopenssh
    $LN /etc/init.d/cswopenssh  /etc/rcS.d/K99cswopenssh
    /etc/init.d/sshd stop && sleep 4
    /etc/init.d/cswopenssh start

    $WGET --output-document='/etc/init.d/cswpuppetd' 'http://ral-satprd01.gpi.com/git/gitweb.cgi/?p=sa-tools.git;a=blob_plain;f=etc/solaris_init.d/cswpuppetd;hb=HEAD'
    /usr/bin/chmod 754 /etc/init.d/cswpuppetd
    /usr/bin/chown root:other /etc/init.d/cswpuppetd
    $LN /etc/init.d/cswpuppetd  /etc/rc0.d/K20cswpuppetd
    $LN /etc/init.d/cswpuppetd  /etc/rc1.d/K20cswpuppetd
    $LN /etc/init.d/cswpuppetd  /etc/rc2.d/K20cswpuppetd
    $LN /etc/init.d/cswpuppetd  /etc/rc3.d/S80cswpuppetd
    $LN /etc/init.d/cswpuppetd  /etc/rcS.d/K20cswpuppetd

    /etc/init.d/cswpuppetd start
fi

# pbis install -- should make this optional...
#   first clear LD_LIBRARY_PATH
LD_LIBRARY_PATH=

PBIS="pbis-sol-`uname -p`.sh"
$WGET http://ral-satprd01.gpi.com/sol/$PBIS
sh $PBIS

# Rename some local users
#u32883 -> joconnor
/opt/csw/bin/gsed -i "s/u32883/joconnor/g" /etc/passwd
/opt/csw/bin/gsed -i "s/u32883/joconnor/g" /etc/shadow
mv /export/home/u32883 /export/home/joconnor
#u57057 -> dperry
/opt/csw/bin/gsed -i "s/u57057/dperry/g" /etc/passwd
/opt/csw/bin/gsed -i "s/u57057/dperry/g" /etc/shadow
mv /export/home/u57057 /export/home/dperry
#u93021 -> lbarbee
/opt/csw/bin/gsed -i "s/u93021/lbarbee/g" /etc/passwd
/opt/csw/bin/gsed -i "s/u93021/lbarbee/g" /etc/shadow
mv /export/home/u93021 /export/home/lbarbee
#t10465 -> dhamilton
/opt/csw/bin/gsed -i "s/t10465/dhamilton/g" /etc/passwd
/opt/csw/bin/gsed -i "s/t10465/dhamilton/g" /etc/shadow
mv /export/home/t10465 /export/home/dhamilton
#t10471 -> awmyhr
/opt/csw/bin/gsed -i "s/t10471/awmyhr/g" /etc/passwd
/opt/csw/bin/gsed -i "s/t10471/awmyhr/g" /etc/shadow
mv /export/home/t10471 /export/home/awmyhr

