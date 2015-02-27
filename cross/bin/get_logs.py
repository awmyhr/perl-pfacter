#!/usr/bin/env python
"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version] groupname

DESCRIPTION

    Uses Ansible to retrieve log files from remote systems.
    'groupname' must be in your inventory file. Each host
    must have the following varialbes:

    -  'host' Representing the shortname (for use in path)
    -  'log'  Full path and name of remote file, minus date
    -  'out'  File name (not path) of destination file

    'log' and 'out' may be group variables. File will be
    copied to '/log/remote/[host]/YYYY-MM-DD/[out]'
"""

__version__ = '1.2.2'
# git repository

import logging
import optparse
import os
import re
import sys
import time
import traceback
import ansible.runner
from pprint import pprint
#from pexpect import run, spawn


def print_out(hostname, message, result, loglevel, debug):
    loglevel('%s => %s', hostname, message)
    if debug:
        logger.debug('\t %s', result)

def main ():
    global options, args
    ## Exit Codes
    SUCCESS   =  0
    NOHOSTS   = 80
    datein    = time.strftime('%Y%m%d')
    dateout   = time.strftime('%Y-%m-%d')
    if options.logds == 'websphere':
        logds = '.' + dateout
    else:
        logds = '-' + datein

    fetchfrom = args[0]
    fetchargs = [ 'src={{ log }}' + logds,
                  'dest=/log/remote/{{ host }}/' + dateout + '/{{ out }}',
                  'validate_checksum=no',
                  'flat=yes' ]

    hosts = ansible.runner.Runner(
       module_name='fetch',
       module_args=' '.join(fetchargs),
       pattern=fetchfrom,
       forks=10
    )
    logger.debug('ansible %s -m fetch -a  "%s"', fetchfrom, ' '.join(fetchargs))
    results = hosts.run()
    logger.debug('==== Object Datastructure =======================')
    logger.debug('%s', vars(hosts))
    logger.debug('=================================================')
    logger.debug('==== Raw Results ================================')
    logger.debug('%s', results)
    logger.debug('=================================================')

    if not hosts.run_hosts:
        logging.critical("No hosts found in group %s", fetchfrom)
        return NOHOSTS

    if 'contacted' in results:
        logger.info('==== FETCHED ====================================')
        for (hostname, result) in results['contacted'].items():
            if (not 'failed' in result) and (result['changed']):
                if ('checksum' in result) and ('remote_checksum' in result):
                    if result['checksum'] == result['remote_checksum']:
                        message = "File successfully transferred"
                    else:
                        message = result
                elif ('md5sum' in result) and ('remote_md5sum' in result):
                    if result['md5sum'] == result['remote_md5sum']:
                        message = "File successfully transferred"
                    else:
                        message = result
                else:
                    message = result
                print_out(hostname, message, result, logging.info, options.debug)
    if 'contacted' in results:
        logger.info('==== SKIPPED ====================================')
        for (hostname, result) in results['contacted'].items():
            if ('failed' in result) or (not result['changed']):
                if 'msg' in result:
                    message = result['msg']
                else:
                    message = 'File already exists'
                print_out(hostname, message, result, logging.warning, options.debug)
    if 'dark' in results:
        logger.info('==== DOWN =======================================')
        for (hostname, result) in results['dark'].items():
            if 'msg' in result:
                if 'Connection timed out' in result['msg']:
                    message = 'Connection timed out'
                elif 'Traceback' in result['msg']:
                    message = result['msg'].split('\n')[-2]
                else:
                    message = result['msg']
            else:
                message = result
            print_out(hostname, message, result, logging.error, options.debug)

    return SUCCESS


if __name__ == '__main__':
    retval = 1
    try:
        start_time = time.time()
        ## Setup and check options
        parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), 
                                       usage=globals()['__doc__'], 
                                       version=globals()['__version__'])
        parser.add_option('-d', '--debug', help='Debug mode',
                          dest='debug', action='store_true', default=False)
        parser.add_option('-f', '--file',  help='Log output to file',
                          dest='outfile', type='string')
        parser.add_option('--datestamp',  help='Datestamp formate of source log',
                          dest='logds', type='string', default='logrotate')
        (options, args) = parser.parse_args()
        if len(args) < 1:
            parser.error ('Missing groupname argument.')
        ## if no log file specified, make a temporary one
        if not options.outfile:
            options.outfile = '/tmp/.getlogfiles-' + time.strftime('%Y%m%d-%H%M')
        if (options.logds != 'logrotate') and (options.logds != 'websphere'):
            parser.error ('Invalid log datestamp. Must be one of: logrotate websphere')
        ## Setup logging
        level = logging.DEBUG if options.debug else logging.INFO
        logger = logging.getLogger()
        #Console output
        console = logging.StreamHandler()
        console.setLevel(level)
        formatter = logging.Formatter('%(levelname)-8s %(message)s')
        console.setFormatter(formatter)
        logger.addHandler(console)
        #File output
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
