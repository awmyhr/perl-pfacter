#!/usr/bin/env python
"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version]

DESCRIPTION

    Retreive list of managed LPARs on an HMC and format them for output,
    or save to a JSON file.
"""

__version__ = '0.1.0'
# git repository

import optparse
import os
import re
import subprocess
import sys
import time
import traceback
#from pexpect import run, spawn


def main ():
    ## Exit Codes
    SUCCESS     =  0

    global options, args
    host      = 'hmc4.gpi.com'
    command   = 'lssyscfg'
    arguments = ' -r sys -F "name,state"'

    ssh = subprocess.Popen(['ssh', host, command + arguments],
                           shell=False,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    try:    
        result = [x.strip() for x in ssh.stdout.readlines()]
    except:
        error = ssh.stderr.readlines()
        print >>sys.stderr, "ERROR: %s" % error
    else:
        print result

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
