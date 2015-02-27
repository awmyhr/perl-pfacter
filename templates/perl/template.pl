#!/usr/bin/perl -w
#
# Program description here
#
#    Date	History
# xxxx-xx-xx	Initial dev version
#		Basic functionality
#
# Start Date: 	
# Coder List: 	amyhr
# e-mail to:	e-mail address

=pod

=head1 NAME

=head1 DESCRIPTION

=head1 OPTIONS

=over 

=item

=back

=head1 ERRORS

=head1 FILES

=head1 RESTRICTIONS

=head1 AUTHOR

=head1 HISTORY


=cut

use lib "$ENV{HOME}/lib";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program

use vars qw($opt_h $opt_v $opt_V);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
);

#Defaults

#Program info (mostly created by RCS)
$Version	= '0.1';
$Modified	= 'xxxx-xx-xx xx:xx';
$MostRecentCoder= 'name';
$ProgName	= basename("$0");
$Dev		= 1;
						
if( $Dev ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
}

if(!getopts('hvV')) {			#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
        -h		Display this help and exit
	-v		Output version info and exit
	-V		Output verbose version info and exit

Report bugs to amyhr\@sf.net
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created:   Last Modified: $Modified
END_of_text
	exit 0;
}

if($opt_V){				#Display Verbose Version Info from comments above
open(PROG, $0) or die "Sorry, could not read $ProgName: $!\n";
	while(<PROG>)  {
		next if((/^#!/));
		last if(!/^#/);
		print substr($_, 1);
	}
close(PROG);
	print "Current Version: $Version\n";
	exit 0;
}

exit 0;

# FUTURE IDEAS
