#!/usr/bin/perl -w
#
# A Library of functions for retreiving system information. 
# These routines are intended to provide information, which the calling 
#	program is expected to format for it's own use.
# Based in part on my own previous work at getting sysinfo, as well as
#	others.
#
#    Date	History
# 08/25/2004	Initial dev version
#		Basic functionality
# 11/05/2004	Adding reporting of information which is more dynamic in nature
# 11/08/2004	Let's make this a Real Perl Module...
#
# Start Date: 	August 25, 2004
# Coder List: 	awmyhr
# e-mail to:	awmyhr@gmail.com

package SysInfo;
use strict;	
#use 5.006;	#"use warnings" require perl 5.6+
#use warnings;	#This limits the module to perl 5.6+
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter;

@ISA	=qw(Exporter);
@EXPORT	=qw(get_SysInfo_version get_sysinfo get_dynamic_sysinfo get_allinfo);
@EXPORT_OK	=qw(_get_hostname _get_proc_info _get_os_version _get_memory _get_hardware _get_last_boot _bogo_perl_mips);
$VERSION	= 2.2;

=pod

=head1 NAME

Sys::SysInfo - Library of funcions to retrieve system information.

=head1 DESCRIPTION

This library of functions is designed to return detailed system information
in as genral a fashion, and unifrom format, as possible.  The functions will 
return the information, but it's up to the calling program to parse and format
it in the way needed.

=head1 FUNCTIONS

=over 

=cut

#####################################################################################

=item get_SysInfo_version( )

This returns the version of the SysInfo library.  It's intended for the
calling program to check for a minimum version to ensure a function exists.

=cut

sub get_SysInfo_version {	#this is legacy as of version 2.2.  use regular methods for accessing module version info
	return $VERSION;
}

#####################################################################################

=item get_sysinfo( )

This returns all the basic system information in a hash.

=cut

sub get_sysinfo {

	my %sysinfo = (	

		_get_hostname(),
		_get_proc_info(),
		_get_os_version(),
		_get_memory(),
		_get_hardware(),
		#total_swap	=> &get_total_swap,
		#os_version	=> &get_os_version,
		
	);

	#@sysinfo{"model_type", "proc_speed", "sys_arch"} = &get_hardware_info;

	return %sysinfo;

};

#####################################################################################

=item get_dynamic_sysinfo()

This returns all the dynamic system information in a hash

=cut

sub get_dynamic_sysinfo {

	my %dynamicinfo = (
		_get_last_boot(),
		
	);
	
	return %dynamicinfo;
};

#####################################################################################

=item get_allinfo()

This returns all the dynamic & system information in a hash

=cut

sub get_allinfo {

	my %info = (
		get_sysinfo(),
		get_dynamic_sysinfo(),
		
	);
	
	return %info;
};

#####################################################################################

=item _get_hostname( )

This returns the full name, bare hostname and domain name (if known) 
in the keys:

=over

name_host
name_domain
name_full
host_id
net_pri_ip

=back

=cut

sub _get_hostname {
	use Sys::Hostname;
	use Socket;
	my ($fullname, $hostname, $domainname, $hostid, $address);
	$fullname =  Sys::Hostname::hostname();
	if ( $fullname =~ /\./ ) {
		($hostname, $domainname) = split (/\./, $fullname,2);
	} else {
		$hostname = $fullname;
		$domainname = "";
	}
	
	for($^O) {
		/aix|cygwin|linux|solris/i and do {
			chomp( $hostid = `hostid` );
			last;
		};
		
		/bsdos|darwin/i and do {
			chomp( $hostid = `sysctl -n kern.hostid` );
			last;
		};
		
		/hp-?ux/i and do {
			chomp( $hostid = `uname -i` );
			last;
		};
		
		#default
		$hostid = -1;
	};
	
	$address = gethostbyname($hostname) or $address = "unknown";
	if ($address ne "unknown") { $address = inet_ntoa($address); }
	
	return (
		name_host => $hostname,
		name_domain => $domainname,
		name_full => $fullname,
		host_id => $hostid,
		net_pri_ip => $address,
	);
};

#####################################################################################

=item _get_proc_info( )

This returns number of name, type, number, speed of the cpu, and number of bits
the cpu supports in the keys:

=over

cpu_name
cpu_type
cpu_number
cpu_speed
cpu_bits

CPU speed should be returned in MHz.

=back

=cut

sub _get_proc_info {
	my ($num_proc, $type, $speed, $cpu, $cbits);
	
	$cbits = -1;
	$num_proc = -1;
	$type = "unknown";
	$speed = -1;
	$cpu = "unknown";

	for($^O) {
		/aix/ and do {	
			open (LSCFG, "/usr/sbin/lscfg -vp|");
			while (<LSCFG>) {
				next unless $_ =~ m/\s+proc\d{1,}/;
				$num_proc++
			};
			close (LSCFG);
			last;
		};
		
		/bsdos/i and do {  #this is returned by BIG-IP F5
			chomp ( $num_proc = `sysctl -n hw.ncpu` );
			chomp ( $type = `sysctl -n hw.machine` );
			chomp ( $cpu = `sysctl -n hw.model` );
			chomp ( $speed = `sysctl -n kern.cycles_per_second` );
			$speed /= 1000000;
			last;
		};
		
		/darwin/i and do {  
			chomp ( $num_proc = `sysctl -n hw.ncpu` );
			#this just returns "Power Macintosh"
			#chomp ( $type = `sysctl -n hw.machine` );
			#at least in Mac OS X 10.3, this works
			chomp ( $type = `machine` );
			chomp ( $cpu = `sysctl -n hw.model` );
			chomp ( $speed = `sysctl -n hw.cpufrequency` );
			$speed /= 1000000;
			last;
		};
		
		/hp-?ux/ and do {  
			$num_proc = grep /^processor/ => `ioscan -fnkC processor`;
			for(`getconf CPU_VERSION`) {
				/768/ and do { $type = "Itanium 1"; last; };
				/532/ and do { $type = "PA-RISC 2.0"; last; };
				/529/ and do { $type = "PA-RISC 1.2"; last; };
				/528/ and do { $type = "PA-RISC 1.1"; last; };
				/523/ and do { $type = "PA-RISC 1.0"; last; };
				#default
				$type = "PA-RISC 1";
			}

			chomp($cpu = `getconf CPU_CHIP_TYPE`);
			$cpu = unpack("B*", pack("N", $cpu));
			$cpu =~ s/.....$//;
			$cpu = substr(unpack("H*", pack("B32", substr("0" x 32 . $cpu, -32))), -2);
			
			for( $cpu ) {
				/b/ and do { $cpu = "PA7200"; last; };
				/d/ and do { $cpu = "PA7100LC"; last; };
				/e/ and do { $cpu = "PA8000"; last; };
				/f/ and do { $cpu = "PA7300LC"; last; };
				/10/ and do { $cpu = "PA8200"; last; };
				/11/ and do { $cpu = "PA8500"; last; };
				/12/ and do { $cpu = "PA8600"; last; };
				/13/ and do { $cpu = "PA8700"; last; };
				/14/ and do { $cpu = "PA8800"; last; };
				/15/ and do { $cpu = "PA8750"; last; };
				/30/ and do { $cpu = "Itanium"; last; };
				#default
				$cpu = "";
			}
				
			if (! $cpu ) {
				my (@cpu, $model, $lst);
				chomp( $model = `model` );
				$model =~ s:.*/::;
				open LST, "< /usr/sam/lib/mo/sched.models" and
					@cpu = grep m/$model/i, <LST>;
				close LST;

				@cpu == 0 && open LST, "< /opt/langtools/lib/sched.models" and
					@cpu = grep m/$model/i, <LST>;
				close LST;

				if (@cpu == 0 && open LST, "echo 'sc product cpu;il' | /usr/sbin/cstm |") {
					while (<$lst>) {
						s/^\s*(PA)\s*(\d+)\s+CPU Module.*/$model 1.1 $1$2/ or next;
						$2 =~ m/^8/ and s/ 1.1 / 2.0 /;
						push @cpu, $_;
					}
				}
				if ($cpu[0] =~ m/^\S+\s+(\d+\.\d+)\s+(\S+)/) {
					my( $arch, $cpu ) = ("PA-$1", $2);
					use POSIX;
					my $os_version = (POSIX::uname())[2];
					$os_version =~ s/[A-Z].//;
					$type = $os_version >= 11 && `getconf HW_32_64_CAPABLE` =~ m/^1/ ? "$arch/64" : "$arch/32";
				}
			}
			
			#This will find cpu speed, but requires root
			#echo "itick_per_usec/D" | sudo adb /stand/vmunix /dev/mem | tail -1
			$speed = _hp_get_speed();
			
			chomp ($cbits =`getconf HW_CPU_SUPP_BITS` );
			
			last;
		};
		
		/cygwin|linux/ and do {
			#in the future, I'd like to creat a look up table
			# which will match the 'cpu family' number and model
			# number to the actual name of the CPU instead of
			# using the 'model name' string...
			
			my (@cpu_info, $i, $len, $gar);
			
			if (open CPUINFO, "< /proc/cpuinfo") {
				chomp (@cpu_info = <CPUINFO>);
				close CPUINFO;
				$num_proc = 0;
				$i = 0;
				$len = @cpu_info;
				until ($i == $len) {
					if (grep /^vendor_id/i => $cpu_info[$i]) {
						( $gar , $type ) = split(/:/, $cpu_info[$i]);
					}
					if (grep /^model name/i => $cpu_info[$i]) {
						( $gar , $cpu ) = split(/:/, $cpu_info[$i]);
					}
					if (grep /^cpu mhz/i => $cpu_info[$i]) {
						( $gar , $speed ) = split(/:/, $cpu_info[$i]);
					}
					if (grep /^processor/i => $cpu_info[$i]) {
						$num_proc++;
					}
					$i++;
				}
			} 
			
			if($cpu =~ /[mg]hz/i) {
				$cpu =~ s/\s\d+[mg]hz|\s\d+\.\d+[mg]hz//i;
			}
			
			if(-x "/usr/bin/getconf") {
				chomp( $cbits = `getconf WORD_BIT` );
			}
			last;
		};
		
		/solaris|sunos|osf/ and do {  
			my (@psrinfo, $cpu_line);
			@psrinfo  = grep /the .* operates .* mhz/ix => `psrinfo -v`;
			( $type, $speed ) = $psrinfo[0] =~ /the (\w+) processor.*at (\d+) mhz/i;
			#$type =~ s/(v9)$/ $1 ? "-LP64" : "-LP32"/e;
			#could also use isainfo -kv for cbits
			if ($type =~ /v9/) { $cbits = 64; } else { $cbits = 32; }
			$num_proc = scalar (@psrinfo);
			( $cpu_line ) = grep /\s+$speed\s+/i => `prtdiag`;
			( $cpu = ( split " ", $cpu_line )[5] ) =~ s/.*,//;
			last;
		};
		
		#Default
	}
	
	$cpu =~ s/^\s+//;
	$type =~ s/^\s+//;
	$num_proc =~ s/^\s+//;
	$speed =~ s/^\s+//;
	
	return (
		cpu_name => $cpu,
		cpu_type => $type,
		cpu_number => $num_proc,
		cpu_speed => $speed,
		cpu_bits => $cbits,
	);

};

#####################################################################################

=item _get_os_version( )

This returns OS name, version, and revision in the keys:

=over

os_name
os_official_name
os_version
os_revision
os_bits
os_perl_name

=back

=cut

sub _get_os_version {
	
	use POSIX;
	my ($os_version, $os_name, $os_revision, $os_bits, $os_official_name, $os_std_comply);
	
	($os_name, $os_version, $os_revision) = (POSIX::uname())[0,2,3];
	$os_bits = -1;
	$os_std_comply = "unknown";
	
	for($^O) {  
		/aix/i and do {	
			my @ml;
			open (INSTFIX, "/usr/sbin/instfix -i|");
			while (<INSTFIX>) {
				next unless /\s+All filesets for (.*)_AIX_ML/;
				my $ml = $1;
				$ml =~ s/\.//g;
				push (@ml, $ml);
			};
			close (INSTFIX);
			my @ml_sorted = sort { $b cmp $a } @ml;
			$os_revision .= $ml_sorted[0];
			last;
		};
		
		/bsdos/i and do {  #this is returned by BIG-IP F5
			$os_version =~ s/$os_name\s+//;
			$os_revision =~ s/$os_name\s+//;
			chomp ( $os_official_name = `sysctl -n kern.osrelease` );
			last;
		};
		
		/darwin/i and do {
			$os_revision =~ s/:.+//;
			### the following section causes 4 errors in Shell.pm ###
			### and causes this sub to exit - or at least, not work
			### Use of uninitialized value in concatenation (.) or string at /usr/local/cb/perl5.8.4/lib/5.8.4/Shell.pm line 35.
			#open (SYSPROF, "/usr/sbin/system_profiler SPSoftwareDataType |");
			#while(<SYSPROF>) {
			#	next unless /System Version:/;
			#	$os_official_name = $_;
			#	#$os_official_name =~ s/.*://;
			#};
			#close(SYSPROF);
			### end section ###
			$os_official_name =~ s/.*://;
			chomp ($os_official_name);
			last;
		};
		
		/cygwin/i and do {
			$os_official_name = $os_version;
			$os_official_name =~ s/\(.*//;
			$os_official_name = "Cygwin $os_official_name";
		};
		
		/hp-?ux/i and do {
			chomp( $os_bits = `getconf KERNEL_BITS` );
			$os_official_name = $os_version;
			$os_official_name =~ s/[A-Z]\.//;
			if( $os_official_name >= 11.11 ) {
				my ($rev);
				( $os_official_name, $rev )=  split(/\./, $os_official_name);
				for ($rev) {
					/11/ and do { $rev = "1.0"; last; };
					/20/ and do { $rev = "1.5"; last; };
					/22/ and do { $rev = "1.6"; last; };
					/23/ and do { $rev = "2.0"; last; };
					/24/ and do { $rev = "2T"; last; };
					/30/ and do { $rev = "3.0"; last; };
					#default
					$rev = "unknown";
				}
				$os_official_name = "HP-UX 11i v$rev";
			} else {
				$os_official_name = "HP-UX $os_official_name";
			}
			last;
		};
		
		/irix/i and do {  
			$os_revision = `uname -R`;
			$os_revision =~ s/^$os_version\s+(?=$os_version)//;
			last;
		};
		
		/linux/i and do {  
			my $dist_re = '[-_](?:release|version)\b';
			my @distro = grep /$dist_re/ => glob( '/etc/*' );
			my @text; #scratch variable
			
			if ( $distro[0] ) {
				foreach my $dist (@distro) {
					if( $dist =~ /lsb/ ) {
						open(DIST, "< $dist") or $os_std_comply = "";
							@text = <DIST> ;
						close(DIST);
						$os_std_comply = "Linux Standard Base " . join("\n", @text);
						$os_std_comply =~ s/LSB_VERSION=/v/g;
						$os_std_comply =~ s/"//g;
						$os_std_comply =~ s/\n/ /g;
					} elsif( $dist =~ /UnitedLinux/ ) {
						open(DIST, "< $dist") or $os_std_comply = "";
							@text = <DIST>;
						close(DIST);
						$os_std_comply = "United Linux " . join("\n", @text);
						$os_std_comply =~ s/VERSION = /v/g;
						$os_std_comply =~ s/PATCHLEVEL = /r/g;
						$os_std_comply =~ s/"//g;
						$os_std_comply =~ s/\n/ /g;
					} else {
						open(DIST, "< $dist") or $os_official_name = "";
							@text = <DIST>;
						close(DIST);
						$os_official_name = join("\n", @text);
						$os_official_name =~ s/VERSION = /v/g;
						$os_official_name =~ s/\n/ /g;
					}
				}
			}
			last;
		};
		
		/solaris|sunos|osf/i and do {
			if( `isalist` =~ /sparcv9/i ) {
				$os_bits = 64;
			}
			if( $os_version >= 4.1 ) {
				if ( $os_version >= 5.7 ) {
					$os_official_name = "Solaris " . substr("$os_version", 2);
				} else {
					$os_official_name ="Solaris " . ($os_version - 3);
				}
			} else {
				$os_official_name = "SunOS $os_version";
			}
			last;
		};
		
		/windows|mswin32/i and do {  
			eval { require Win32 };
			$@ and last;
			$os_name = join "", Win32::GetOSName();
			$os_version = $^O;
			$os_version =~ s/Service\s+Pack\s+/SP/;
			last;
		};
		
		#Default
	}
	
	return (
		os_version => $os_version,
		os_name => $os_name,
		os_revision => $os_revision,
		os_bits => $os_bits,
		os_perl_name => $^O,
		os_official_name => $os_official_name,
		os_std_comply => $os_std_comply,
	);
};

#####################################################################################

=item _get_memory()

This function returns physical, swap, and total memory in the keys:

=over

mem_total
mem_physical
mem_swap

Memory should be returned in kilobytes.

=back

=cut

sub _get_memory {
	my ($total, $physical, $swap);
	$total = -1; $physical = -1; $swap = -1;
	
	for ($^O) {
		/aix/i and do {
			last;
		};
		
		/cygwin|linux/i and do {
			my (@mem_info, $i, $len, $gar);
			
			if (open MEMINFO, "< /proc/meminfo") {
				chomp (@mem_info = <MEMINFO>);
				close MEMINFO;
				$i = 0;
				$len = @mem_info;
				until ($i == $len) {
					if (grep /^memtotal/i => $mem_info[$i]) {
						( $gar , $physical ) = split(/:/, $mem_info[$i]);
					}
					if (grep /^swaptotal/i => $mem_info[$i]) {
						( $gar , $swap ) = split(/:/, $mem_info[$i]);
					}
					$i++;
				}
			} 
			
			$physical =~ s/\D//g;
			$swap =~ s/\D//g;
			
			last;
		};
		
		/bsdos/i and do {
			$physical = `sysctl -n hw.physmem` / 1024;
			#pstat -s will show swap space, but needs to be run by root
			$swap = 0;
			last;
		};
		
		/darwin/i and do {
			$physical = `sysctl -n hw.memsize` / 1024;
			#unknown how to detect swap at this time
			$swap = 0;
			last;
		};
		
		/hp-?ux/i and do {
			
			#$physical = _hp_get_memory() * 1024;
			open LST, "< /var/adm/syslog/syslog.log" and
				( $physical ) = grep m/Physical/, <LST>;
			close LST;
			$physical =~ s/^.*P//;
			$physical =~ s/Kbyte.*$//;
			$physical =~ s/^\D+//;
			chomp ($physical);
			#swapinfo -a will show swap space, but needs to be run by root
			$swap = 0;
			last;
		};
		
		/solaris/i and do {
			my ($mem_line, @swap_list, $i, $len);
			( $mem_line ) = grep /^Memory/ => `prtdiag`;
			$physical = $mem_line;
			$physical =~ s/\D+//g;
			if ( $mem_line =~ /megabyte/i ) {
				$physical *= 1024;
			}
			
			@swap_list = `/usr/sbin/swap -l`;
			$swap = 0;
			$i = 0;
			$len = @swap_list;
			until ($i == $len) {
				if ( $swap_list[$i] !~ /^swapfile/ ) {
					$swap += (split " ", $swap_list[$i])[4];
				}
				$i++;
			};
			$swap /= 2;
			
			last;
		};
		
		#default
	}
	
	if ($total == -1) { $total = $physical + $swap; }
	
	return (
		mem_total => $total,
		mem_physical => $physical,
		mem_swap => $swap,
	);
		
};

#####################################################################################

=item _get_hardware()

This function returns hardware name & architecture in the keys:

=over

hw_name
hw_arch
hw_perl_arch

=back

=cut

sub _get_hardware {
	my ( $hwname, $arch );
	use POSIX;
	use Config;
	
	( $arch ) = (POSIX::uname())[4];
	
	for($^O) {
		/hp-?ux/i and do {
			chomp( $hwname = `model` );
			last;
		};
		
		/solaris/i and do {
			( $hwname ) = grep /^System Configuration/ => `prtdiag`;
			$hwname =~ s/^.*sun4u\s+|\s+\(.*//g;
			chomp( $hwname );
			last;
		};
		
		#note: I know of no reliable way to get hardware name for
		#	cygwin/linux/bsdos/any x86 os
		#default
		$hwname = "unknown";

	}
	
	return (
		hw_name => $hwname,
		hw_arch => $arch,
		hw_perl_arch => $Config{'archname'},
	);
};

#####################################################################################

=item _get_last_boot()

Returns a hash with the following keys:

=over

dynamic_sys_lboot
dynamic_sys_uptime

=back

=cut

sub _get_last_boot {
	use Shell qw(who uptime);	#Going to use the who command
	#Parameters are:
	
	#Local variables
	my($uptime, @uptime, $lboot);
	
	#there seems to be some problem with this redirection on
	#  solaris 2.6 with v5.005_03 of perl which I can't reproduce
	#  on the command line.  I'm ignoring it for now...
	if( !($lboot = who("-b","2> /dev/null")) ) {
		$lboot = "unknown";
	} else {
		chomp($lboot = substr($lboot, index($lboot, "ot") + 4));
	}
	
	@uptime = split(/,/, uptime());
	$uptime = substr($uptime[0], index($uptime[0], "up") + 3) . " $uptime[1]";
	
	return (
		dynamic_sys_lboot => $lboot,
		dynamic_sys_uptime => $uptime,
	);
};

#####################################################################################

=item _hp_get_speed( )

This is an internal function which builds an executable to determine the cpu
speed, runs it and removes it.  This is needed becouse I could not find a 
way to get this info via script w/o being root.  This is directly from 
Ian P. Springer's 'stats' version 1.7.1.

=cut

sub _hp_get_speed {
	my ($cpuspeedc, $cpuspeed, $speed);
	
	$cpuspeedc = "/tmp/cs.c";
	$cpuspeed = "/tmp/cpus";
	
	open(CPUS, "> $cpuspeedc") or return -1;
print CPUS <<END_of_text;
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/param.h>
#include <sys/pstat.h>
#define CPU_ID 0
#define HZ_PER_MHZ 1000000
main(){
	struct pst_processor pst;
	union pstun pu;
	pu.pst_processor = &pst;
	if ( pstat( PSTAT_PROCESSOR, pu, (size_t)sizeof(pst), 
		(size_t)1, CPU_ID) != -1 ) {
		printf( "%d",
			(int)((double)pst.psp_iticksperclktick * 
			sysconf( _SC_CLK_TCK ) / HZ_PER_MHZ) );
		exit( 0 );
	} else {
		perror("pstat");
		exit( errno );
	}
}

END_of_text
	
	close CPUS;
	
	`cc -o $cpuspeed $cpuspeedc >/dev/null 2>&1`;
	
	$speed = `$cpuspeed`;
	
	unlink $cpuspeed, $cpuspeedc;
	
	return $speed;
};

#####################################################################################

=item _hp_get_memory( )

This is an internal function which builds an executable to determine the amount
of memory, runs it and removes it.  This is needed becouse I could not find a 
way to get this info via script w/o being root.  This is directly from 
Ian P. Springer's 'stats' version 1.7.1.

=cut

sub _hp_get_memory {
	my ($memoryc, $memory, $size);
	
	$memoryc = "/tmp/ms.c";
	$memory = "/tmp/ms";
	
	open(MEMS, "> $memoryc") or return -1;
#(long)( (double)pst.psd_vm * pst.page_size / BYTES_PER_MB )  <<-- doesn't work!! "total virtual memory"
print MEMS <<END_of_text;
#include <errno.h>
#include <stdio.h>
#include <sys/param.h>
#include <sys/pstat.h>
#define BYTES_PER_MB 1048576
main() {
	struct pst_static pst;
	union pstun pu;
	pu.pst_static = &pst;
	if ( pstat( PSTAT_STATIC, pu, (size_t)sizeof(pst), 
		(size_t)0, 0 ) != -1 ) {
		printf( "%ld", 
			(long)( (double)pst.physical_memory * 
			pst.page_size / BYTES_PER_MB ) );
		exit( 0 );
	} else {
		perror("pstat");
		exit( errno );
	}
}
END_of_text
	
	close MEMS;
	
	`cc -o $memory $memoryc >/dev/null 2>&1`;
	
	$size = `$memory`;
	
	unlink $memory, $memoryc;
	
	return $size;

};

#####################################################################################

=item _bogo_perl_mips()

This internal funcion returns the amount of time it takes to run an arbitray loop
one million times in the form of a "BogoPerlMIP".  This is "just for fun"...

=cut

sub _bogo_perl_mips {
	use Benchmark;
	
	my($t, $i, $count);
	$count=10000000;
	$i = 0;
	
	$t = timeit($count, ' $i++ ' );
	
	print "$count loops of other code took:", timestr($t), "\n";
	
	print "benched w/timethis(): ", timethis($count, ' $i++' ),  "\n";
	
	my($t1, $t2);
	$t1=time();
	for($i=0;$i<$count;$i++) {};
	$t2=time();
	
	print "$t2 - $t1 = " , $t2 - $t1 , "\n";
	
	return;
};

# FUTURE IDEAS


1; #Leave this here, perl needs it...

=back

=head1 WARNING

I have only tested this library extensivly on the following systems:

=over

=item * i686 Cygwin 1.5.11 (IBM Thinkpad T30)

=item * i686 linux 2.4.18 [RH 7.3] & 2.4.21 [RHEL 3.0] (HP DL380)

=item * i386 BIG-IP 4.2 [bsdos based] (F5 Loadbalancer 520)

=item * sparc Solaris 8 (Sun 220r)

=item * sparc Solaris 2.6 (Ultra 5)

=item * pa-risc hp-ux 11i v1.0 (HP N4000-55)

=item * s390 linux 2.4.21 [SuSE SLES v8.1] (zOS S390 node)

=back

All other code/sytem setups are untested.  If you get a chance to test it, 
please let me know the results...

=head1 AUTHOR

   Andy MyHR
   <mailto: amyhr@gmail.com>
   
   Parts of this program are either from, or inspired by, the works of:
   Sandor W. Sklar (AIX::SysInfo.pm) <mailto:ssklar@stanford.edu>
   Abe Timmerman (Test::Smoke::SysInfo.pm) <abeltje@cpan.org>
   Ian P. Springer (stats160.ksh, stats171.ksh) <ian_springer@am.exch.hp.com>
   Jeffrey Dunitz (SysInfo.ksh)
   Steve Walker (check)

   There may be others I've forgotten.  Please let me know if you believe
   your name should be on this list
   
=head1 HISTORY

$Log: SysInfo.pm,v $
Revision 2.2  2004/11/11 22:56:56  myhra01
this is now a 'real' perl module
other minor changes

Revision 2.1  2004/11/05 21:36:08  myhra01
adding whole new reporting system with get_dynamic_sysinfo().  This and get_sysinfo should be oneline hashes.  Future reports with multiple lines (i.e., a function which returns the top 10 processes) will be their own subroutine.
Tossed around the idea of consolidating all checks for each OS into their own subroutines, but ultimately decided against that.  I want to be able to call for specific information without getting everything.  In the future, I may break out everything into it's own function, or each set of OS specific functions will have it's own file, but for now it stands as it is (functions seperated by info gathered, not OS)...

Revision 1.9  2004/09/07 20:41:03  myhra01
added get_hardware() which will, on some systems, return the name of the hardware it's running on, as well as what perl thinks the architecture is
also added a couple more minor keys, and cleaned up some code

Revision 1.8  2004/09/03 18:28:55  myhra01
minor edits, minor bug-fixes, minor elements added

Revision 1.7  2004/09/03 16:57:26  myhra01
added bsdos (BIG-IP) support as well as some additional return keys

Revision 1.6  2004/09/01 21:26:00  myhra01
added get_memory() for hp-ux, though it currently only returns physical memory
minor formatting issues

Revision 1.5  2004/09/01 20:33:49  myhra01
added get_memory(), which is now working for cygwin/linux and solaris

Revision 1.4  2004/09/01 18:07:59  myhra01
all end-user functions now return hashes. added 64 cpu and os detection for hp-ux and solaris

Revision 1.3  2004/08/31 19:25:28  myhra01
get_hostname(), get_proc_info(), and get_os_version() working on cygwin, linux, hp-ux, and solaris

Revision 1.2  2004/08/27 20:55:31  myhra01
get_hostname() & get_os_version() functionality working
internal get_SysInfo_version() function working

Revision 1.1  2004/08/27 20:24:58  myhra01
Initial revision

=head1 COPYRIGHT

(c) 2004, Andy MyHR <amyhr@gmail.com> All rights reserved.

With contributions from Sandor W. Sklar, Abe Timmerman, Jeffrey Dunitz
and Steve Walker.  To the best of my knowledge, all code which is not
mine is freely avilable, often under the same terms as Perl itself.  If
you see code which you believe shouldn't be here, please contact me.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  If you do redistribute and/or 
modify, I would like to be notified.

See:

=over 

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


=cut
