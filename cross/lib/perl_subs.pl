#!/usr/local/bin/perl -w
# These are perl subroutines to support various programs
#   implemented in css
#
# Version History
#   0.2   Initial version
#         Basic functionality
#         MailError(To Address, Subject, Message, Fatal or not (0|1));
#   0.4   DateStamp();
#   0.6   Added functionality to DateStamp() to allow new formats
#         DateStamp(n);
#   0.7   Added paramater to DateStamp() to allow for change in day
#         DateStamp(n, n);
#   1.0   Needed to make a "release" version, as this really isn't in beta
#         Added new date format to DateStamp() and reformated long if/elsif/else block
#         Added InArray()
#           InArray(StringToMatch, ArrayToCheck);
#         Fixed bug in DateStamp option 2 which incorrectly formated one digit days
#  02/26/2003	Added new format to DateStamp()
#		Minor formating work to conform with template.pl v2
#  02/28/2003	Added perl_subs_version() to check version of file
#  03/18/2003	changed 'mailx' to 'mail' in MailError()
#		   (note: cannot use Mail::Mailer as it is not a std lib)
#		Added MoreFiles() and SortTime()
#  03/21/2003	changed 'mail' in MailError() to a variable which is set after
#		   checking for /usr/bin/mailx
#  03/31/2004	Added leastPerlsubsVersion to return true if this lib is at
#			least the version quaried, otherwise false
#		Added GetOutput() and ReadFile()
#		Made file self-executable to return list of routines
#		^^^ this is done by adding -h/-v/-V options to the file
#  04/01/2004	Options (-h/-v/-V) interfere with the options of the calling program
#		^^^ solved by checking for 'perl_subs' in $0 - needs improvement
#
# Start Date: May 09, 2001
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com
#$Id: perl_subs.pl,v 1.14 2004/05/06 17:50:49 myhra01 Exp myhra01 $

if ($0 =~ /perl_subs/) {

	use strict;				#Turn on strict, good programing
	use Getopt::Std;			#Parser for command line options
	use File::Basename;			#Used to get name of program

	use vars qw($opt_h $opt_v $opt_V);

	if(!getopts('hvV')) {			#Check options and warn if errors
		print "Usage: $0 [OPTIONS]\n";
		print "Try ' -h' for more information.\n";
		exit 1;				#Exit if incorrect options
	}

	if($opt_h) { 				#List subroutines provided
		print <<END_of_text;
This is a library of perl subroutines compiled and (mostly)
written by Andy MyHR.  The best location for this is in your
\@INC path.  Here is what is included:

perl_subs_version()
leastPerlsubsVersion(version-to-check)
MailError(to-address, subject, message body, fatel flag)
DateStamp(format)
	where format =
		1 - Year-Month-Day  Ex: 2001-08-15
		2 - Month Day       Ex: Aug 15
		3 - Month/Day       Ex: 08/15
		4 - MonthDay        Ex: 0815
		5 - Month Day, Year (Hour:minute)  Ex: Aug 15, 2002 (12:12)
InArray(string-to-find, array-to-look-in)
MoreFiles(basefile-name, section-to-request, base URL for links)
SortTime(first-time, second-time)
GetOutput(program-to-run, message-to-return-for-failure, optional filter)
ReadFile(file-to-read, message-to-return-for-failure, optional filter)
END_of_text

	}

	if($opt_v) { print perl_subs_version(); }
	
	if($opt_V) { 
	open(PROG, $0) or die "Sorry, could not read $0: $!\n";
		while(<PROG>)  {
			next if((/^#!/));
			last if(!/^#/);
			print substr($_, 1);
		}
	close(PROG);
		print perl_subs_version(); 
	}

}

#####################################################################################
#Subroutine - get version info

sub perl_subs_version {
	my($Version, $Modified, $MostRecentCoder, $Data);
	
	$Version	= substr('$Revision: 1.14 $', 10, -1);
	$Modified	= substr('$Date: 2004/05/06 17:50:49 $', 6, -1);
	$MostRecentCoder= substr('$Author: myhra01 $', 8, -1);
	
	$Data = <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: 2001/05/09 Last Modified: $Modified
END_of_text

	return $Data;
}

#####################################################################################
#Subroutine - check version 

sub leastPerlsubsVersion {
	#Parameters are:
	#	$chkVersion = least acceptable version number
	my($chkVersion) = @_;

	#Local Vars
	my($Minor, $Major, $chkMinor, $chkMajor);
	
	($Minor, $Major)	= split(/\./, substr('$Revision: 1.14 $', 10, -1) );
	($chkMinor, $chkMajor)	= split(/\./, $chkVersion);
	
	if( ($Major > $chkMajor) ) {
		return 1;
	} elsif( ($Major == $chkMajor) && ($Minor >= $chkMinor) ) {
		return 1;
	} else {
		return 0;
	}
}

#####################################################################################
#Subroutine - Sending mail

sub MailError {
	
	#Parameters are:
	#	$TOADD - To Address
	#	$SUB - Subject
	#	$MESS - Message body
	#	$FATAL - is error fatal? (0=no, 1=yes)
	
	#Variables
	my($TOADD, $SUB, $MESS, $FATAL)=@_;  #parameter list
	my($MailProg);
	
	if(!(-e '/usr/bin/mailx')) {
		$MailProg = "mail ";
	} else {
		$MailProg = "mailx ";
	}
	
	open MAIL, "|$MailProg -s $SUB $TOADD" or die "$MESS\n and I can't open $MailProg $!";
		print MAIL "$MESS\n";	#these three lines send the mail
	close MAIL  or die "$MESS\n and I can't close mail $!";
	
	if($FATAL){ die "$MESS"; }	#This will exit the program with error message
	
	return 0;
}

#####################################################################################
#Subroutine - get a Date Stamp

sub DateStamp{

	my($minute, $hour, $mday, $mon, $year, $Month, @Month, $Date, $opt, $opt2);
	
	$opt = defined($_[0]) ? $_[0] : 1;	
					#if there is a paramater, set $opt to it, else set $opt to 1
					#it is set to 1 due to legacy programs using this routine
					# (and not passing any paramaters) expecting the format defined here
					#  1 - Year-Month-Day	Ex: 2001-08-15
					#  2 - Month Day	Ex: Aug 15
					#  3 - Month/Day	Ex: 08/15
					#  4 - MonthDay		Ex: 0815
					#  5 - Month Day, Year (Hour:minute)	Ex: Aug 15, 2002 (12:12)
	$opt2 = defined($_[1]) ? $_[1] : 0;
					#if there is a second parameter, set $opt,
					# to it, else set to 0.  This is the number
					#of days to offset returned value by.
					
					#First prepare the date variables
	($minute,$hour,$mday,$mon,$year)=(localtime(time + (86400 * $opt2)))[1,2,3,4,5];
	@Month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	$Month = $Month[$mon];
	
	$year = $year + 1900;
	$mon++;
	
	$mon = ($mon < 10) ? "0$mon" : $mon;
					# pad month if necessary (< 10)
	$mday = (($mday < 10) && ($opt != 2)) ? "0$mday" : $mday;
					# pad day of month if necessary (< 10 and not option 2)
	
	for($opt) {			# perl has no switch/case statement :-(
		/1/ and do {
			$Date = "$year-$mon-$mday";
			last;		#A bit of trivia:  this is the "ISO 8601 approved" format
		};
		/2/ and do {
			if($mday < 10) {$mday = " $mday";}
			$Date = "$Month $mday";
			last;
		};
		/3/ and do {
			$Date = "$mon/$mday";
			last;
		};
		/4/ and do{
			$Date = "$mon$mday";
			last;
		};
		/5/ and do{
			$Date = "$Month $mday, $year ($hour:$minute)";
			last;
		};
		
		#Default, This SHOULD never execute, we'll see...
		$Date = localtime;
	}
	
	return $Date;
}

#####################################################################################
#Subroutine - Find if a string is in an array

sub InArray() {
	#Parameters are:
	#	$string - string to find
	#	$array - array to look in
	my($string, @array) = @_;

	#Local variables
	my($data, $i, $len);
	$data = 0;
	$i = 0;
	$len = @array +1;

	until(($data == 1) || ($i == $len)) {
		if( $array[$i] =~ /$string/) {
		#if($array->[$i] eq $string){
			$data = 1;
		}
		$i++;
	}

	return $data;
}

#####################################################################################
#Subroutine - create links for archive files

sub MoreFiles {
	use File::Basename;		#For filename manipulation (namely fileparse)	
	use POSIX qw(uname);		#get hostname
	
	#Parameters are:
	#	$basefile - basefile name
	#	$section - section to request
	#	$baseurl - base URL for links
	my($basefile, $section, $baseurl) = @_;

	#Local Variables
	my($data, $path, $base, $ext, @filelist, $hostname, $fullurl);
	$data = "Privous days: ";
	$hostname=(uname)[1];
	($base, $path, $ext) = fileparse("$basefile", '\.[0-9][0-9]');

	opendir(DIR, "$path") or $data .= "Problem finding directory $path: $!\n";
		@filelist = grep /$base./, readdir(DIR);
	closedir(DIR);
	
	foreach (sort @filelist) {
		($base, $path, $ext) = fileparse("$_", '\.[0-9]');
		$ext = substr($ext, 1);
		$fullurl = "${baseurl}system&$hostname&POPUP!$hostname!$ext!$section";	
		$data .= "<a href=\"$fullurl\" onClick=\"window.open(\'$fullurl\');return false\">$ext</a>&nbsp;";
	}
	
	return $data;
}

#####################################################################################
#Subroutine - Sort items based on time (HH:MM[:SS])
sub SortTime {
	my($a, $b) = @_;
	
	my(@a, @b);
	@a = split(/:/, $a);
	@b = split(/:/, $b);
	if($a[0] =~ /\D/) { return -1; }
	if($b[0] =~ /\D/) { return 1; }
	
	if($a[0] > $b[0]){
		return 1;
	} elsif($a[0] < $b[0]){
		return -1;
	} else {			#a0 and b0 are equal
		if($a[1] > $b[1]){
				return 1;
		} elsif($a[1] < $b[1]){
			return -1;
		} else {		#a1 and b1 are equal
			if( (! $a[2]) || (! $b[2]) ) {	#no seconds...
				return 0;
			} elsif($a[2] > $b[2]){
				return 1;
			} elsif($a[2] < $b[2]){
				return -1;
			} else {	#a2 and b2 are equal
				return 0;
			}
		}
	}
	
}

#####################################################################################
#Subroutine - Gets output from external command

sub GetOutput {
	#Paramater:
	#	$proggy = program to run
	#	$fail = message to return in case of failure
	#	$filter = optional filter to apply to file
	my($proggy, $fail, $filter) = @_;
	
	#Local Variables
	my($data);
	
	$data="";
	if(!defined($filter)) {$filter = ".|\n";}
	
	open(PROG, "$proggy |") or return "$fail: $!\n";
		while(<PROG>) {
			if($_ =~ /$filter/) {
				$data .= $_;
			}
		}
	close(PROG);
	
	return $data;
}

#####################################################################################
#Subroutine - Read contents of a text file into a variable

sub ReadFile {
	#Paramater:
	#	$file = file to read
	#	$fail = message to return in case of failure
	#	$filter = optional filter to apply to file
	my($file, $fail, $filter) = @_;
	
	#Local Variables
	my($data);
	
	$data="";
	if(!defined($filter)) {$filter = ".|\n";}
	
	open(FILE, "$file") or return "$fail: $!\n";
		while(<FILE>) {
			if($_ =~ /$filter/) {
				$data .= $_;
			}
		}
	close(FILE);
	
	return $data;
}

# FUTURE IDEAS

1 #Leave this here, perl needs it...
