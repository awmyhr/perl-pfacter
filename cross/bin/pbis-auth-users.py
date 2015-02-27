#!/usr/bin/env python

"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version] [-f <file>, --file=<file>]

DESCRIPTION

    Script to report users authorized by PBIS.
    By default the list is printed to stdout, but
    a JSON formated objct can be saved to a file
    with the -f option.


EXIT STATUS

    80  Most likely PBIS is not insalled & working

AUTHOR

    awmyhr <Andy.MyHR@carquest.com>

LICENSE

    This script is in the public domain, free from copyrights or restrictions.

"""

__version__ = '1.0.1'
# git repository

import json
import optparse
import os
import re
import subprocess
import sys
import time
import traceback

def getGroupList():
    """Return group array"""
    try:
        gl = subprocess.Popen(['/opt/pbis/bin/config', '--show', 'RequireMembershipOf'],
                              stdout=subprocess.PIPE)
        (output, err) = gl.communicate()
    except OSError:
        raise RuntimeError('PBIS likely not installed.')
        return ERR_NOPBIS
    groups = output.splitlines()
    try:
        groups.remove('multistring')
        groups.remove('local policy')
        groups.remove('')
    except ValueError:
        pass
    regex = re.compile(r"^.*\\")
    groups = [regex.sub('', g) for g in groups]
    return groups

def getGroupMembers(group):
    """Return hash of group members (username/GECOS)"""
    list = ['UNIX', 'GECOS']
    members = []
    try:
        gl = subprocess.Popen(['/opt/pbis/bin/enum-members', group],
                              stdout=subprocess.PIPE)
        (output, err) = gl.communicate()
    except OSError:
        raise RuntimeError('PBIS likely not installed.')
        return ERR_NOPBIS
    for line in output.splitlines():
        if any(word in line for word in list):
            line = line.split(': ')[1]
            members.append(line)
    
    return dict(zip(members[0::2], members[1::2]))

def main():
    ## Initilizations
    members     = {}
    global opts, args

    ## Handle Options
    if opts.debug:
        print "Debug mode enabled."
        if opts.outfile:
            print "Output file: ", opts.outfile
    ## Get group list
    try:
        grouplist = getGroupList()
    except Exception, err:
        traceback.print_exc()
        return ERR_NOPBIS

    ## Get members of each group
    try:
        for group in grouplist:
            members[group] = getGroupMembers(group)
    except Exception, err:
        traceback.print_exc()
        return ERR_NOPBIS

    if opts.debug:
        print "Group list: ", grouplist
        for key, value in members.iteritems():
            print key, ' => ', value

    ## Write to output file
    if opts.outfile:
        try:
            with open(opts.outfile, 'w') as output:
                json.dump(members, output, indent=1, separators=(',', ': '))
        except:
            print "Unexpected error:", sys.exc_info()[0]
            raise

    else:
        template = "{0:4}|{1:9}{2:20}"
        for group, memlist in members.iteritems():
            print group
            for uid, gecos in memlist.iteritems():
                print '\t', uid.rjust(9), '  ', gecos

    return SUCCESS

### END OF main() ###

if __name__ == '__main__':
    ## Exit Codes
    SUCCESS     =  0
    ERR_NOPBIS  = 80
    retval = 1
    try:
        start_time = time.time()
        parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), 
                                       usage=globals()['__doc__'], 
                                       version=globals()['__version__'])
        parser.add_option('-d', '--debug', help='Debug mode',
                          dest='debug', action='store_true', default=False)
        parser.add_option('-f', '--file',  help='Output file',
                          dest='outfile', type='string')
        (opts, args) = parser.parse_args()
        #if len(args) < 1:
        #    parser.error ('missing argument')
        if opts.debug: print time.asctime()
        retval = main()
        if opts.debug: 
            print time.asctime()
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
