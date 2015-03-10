#!/usr/bin/env python
"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version] <groupname>

DESCRIPTION

    This will check the provided ansible groupname for swap usage and low-
    memory conditions. If no groupname is provided, will default to 'sa'.

"""

__version__ = '1.0.0'
# git repository

import ansible.runner
import logging
import optparse
import os
import re
import sys
import time
import traceback
#from pexpect import run, spawn


def prettyprint(d, indent=0):
   for key, value in d.iteritems():
      print '\t' * indent + str(key)
      if isinstance(value, dict):
         prettyprint(value, indent+1)
      else:
         print '\t' * (indent+1) + str(value)

def main ():
    global options, args
    ## Exit Codes
    SUCCESS     =  0
    phosts      = {}

    hosts = ansible.runner.Runner(
       module_name='command',
       module_args='/bin/cat /proc/meminfo',
       pattern=groupname,
       forks=10
    )
    results = hosts.run()

    if not hosts.run_hosts:
        logging.critical("No hosts found in group %s", fetchfrom)
        return NOHOSTS
    if 'contacted' in results:
        for (hostname, result) in results['contacted'].items():
            phosts[hostname] = {}
            result = result['stdout'].translate(None, ' kB').split()
            for entry in result:
                key, value = entry.split(':')
                phosts[hostname].update({ key: int(value) })
        for host, hostinfo in phosts.iteritems():
            if ((hostinfo['SwapTotal'] - hostinfo['SwapFree']) > 0):
                logging.warning("%-25s is using %dmB swap!", host, (hostinfo['SwapTotal'] - hostinfo['SwapFree'])/1024)
            if (hostinfo['MemFree'] < 131072):
                logging.critical("%-25s has only %dmB memory free!", host, hostinfo['MemFree']/1024)
            elif (hostinfo['MemFree'] < 262144):
                logging.warning("%-25s has only %dmB memory free.", host, hostinfo['MemFree']/1024)
            elif (hostinfo['MemFree'] < 524288):
                logging.info("%-25s has %dmB memory free.", host, hostinfo['MemFree']/1024)
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
        parser.add_option('-f', '--file',  help='Log output to file',
                          dest='outfile', type='string')
        (options, args) = parser.parse_args()
        if len(args) < 1:
            groupname = 'sa'
        else:
            groupname   = args[0]
        #    parser.error ('missing argument')
        if not options.outfile:
            options.outfile = '/tmp/.getlogfiles-' + time.strftime('%Y%m%d-%H%M')
        level = logging.DEBUG if options.debug else logging.INFO
        logger = logging.getLogger()
        #Console output
        console = logging.StreamHandler()
        console.setLevel(level)
        formatter = logging.Formatter('%(levelname)-8s %(message)s')
        console.setFormatter(formatter)
        logger.addHandler(console)
        #File output
        if options.debug or options.outfile:
            logfile = logging.FileHandler(options.outfile,"w", encoding=None, delay="true")
            logfile.setLevel(level)
            formatter = logging.Formatter('%(levelname)-8s %(message)s')
            logfile.setFormatter(formatter)
            logger.addHandler(logfile)

        ## Start of output
        logger.debug('START:  %s', time.asctime())
        #### MAIN() ####
        retval = main()
        ################
        logger.debug('FINISH: %s', time.asctime())
        logger.debug('TOTAL TIME IN MINUTES: %s', (time.time() - start_time) / 60.0)

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
