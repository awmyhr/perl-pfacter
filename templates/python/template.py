#!/usr/bin/env python
"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version]

DESCRIPTION

    TODO This describes how to use this script. This docstring
    will be printed by the script if there is an error or
    if the user requests help (-h or --help).

EXAMPLES

    TODO: Show some examples of how to use this script.

EXIT STATUS

    TODO: List exit codes

AUTHOR

    TODO: Name <name@example.org>

LICENSE

    This script is in the public domain, free from copyrights or restrictions.

"""

__version__ = '0.0.0'
# git repository

import optparse
import os
import re
import sys
import time
import traceback
#from pexpect import run, spawn


def main ():
    ## Exit Codes
    SUCCESS     =  0

    global options, args
    # TODO: Do something more interesting here...
    print 'Hello world!'

    return SUCCESS


if __name__ == '__main__':
    retval = 1
    try:
        start_time = time.time()
        parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), 
                                       usage=globals()['__doc__'], 
                                       version=globals()['__version__'])
        parser.add_option('-d', '--debug', help='Debug mode',
                          dest='debug', action='store_true', default=False)
        (options, args) = parser.parse_args()
        #if len(args) < 1:
        #    parser.error ('missing argument')
        if options.debug: print 'START:  ', time.asctime()
        retval = main()
        if options.debug: 
            print 'FINISH: ', time.asctime()
            print 'TOTAL TIME IN MINUTES:',
            print (time.time() - start_time) / 60.0
        sys.exit(retval)
    except KeyboardInterrupt, e: # Ctrl-C
        raise e
    except SystemExit, e: # sys.exit()
        raise e
    except Exception, e:
        print 'ERROR, UNEXPECTED EXCEPTION'
        print str(e)
        traceback.print_exc()
        os._exit(1)
