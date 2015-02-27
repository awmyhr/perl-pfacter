#!/usr/bin/perl-xuc -w
#
# Program description here
#
# Version History (Update Version & Modified variable also)
#   0.1   Initial dev version
#         Basic functionality
#
# Start Date: 
# Coder: 
# e-mail to: unixnorth@iftafs01.xcelenergy.com

use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options

use vars qw($opt_h $opt_v);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Variable: Verison
	$Modified,			#Variable: Date last modified
	$Dev,				#Variable: Development version?
	$ProgName,			#Variable: Program Name
);

#Defaults
$Version=0.1;
$Modified="";
$Dev=0;
						
if( ($Version * 10) % 2 ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hv')) {			#Check options and warn if errors
	print "Usage: \n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	
        -h		Display this help and exit
	-v		Output version infromaiton and exit
Report bugs to unixnorth\@iftafs01.xcelenergy.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
$Version  
By: amyhr
Date Created:   Last Modified: $Modified
END_of_text
	exit 0;
}

exit 0;

# FUTURE IDEAS
