#!/usr/bin/env python

"""
SYNOPSIS

    %prog [-h,--help] [-d,--debug] [--version] [--prod] [--qa] [--dev]

DESCRIPTION

    Script to migrate errata/package updates on satellite server
    up the environments. If no environment flags are given, then
    script defaults to all three. This assumes your channel labels
    are flagged with 'prod', 'qa', and 'dev'; and that they are 
    cloned appropriately.
"""
__version__ = '2.1.2'
# git repository

import json
import optparse
import os
import re
import socket
import sys
import time
import traceback
import xmlrpclib

def getConf():
    """Retreive & return configuration settings"""
    try:
        with open('/etc/satellite_api.conf') as config_file:
            sinfo = json.load(config_file)
    except IOError as e:
        raise RuntimeError("I/O error({0}): {1}".format(e.errno, e.strerror))
    except ValueError:
        raise RuntimeError("There is a problem with the configuration file.")
    except:
        raise RuntimeError("Unexpected error:", sys.exc_info()[0])
    if 'sserver' not in sinfo: raise RuntimeError("Server name missing in config.")
    if 'suser'   not in sinfo: raise RuntimeError("Server user missing in config.")
    if 'spass'   not in sinfo: raise RuntimeError("Server pass missing in config.")
    return (sinfo['sserver'], sinfo['suser'], sinfo['spass'])


def satLogin(sserver, suser, spass):
    """Return session object. Input: string server, string user, string password"""
    client = xmlrpclib.ServerProxy('http://' + sserver + '/rpc/api', verbose=0)
    try:
        key    = client.auth.login(suser,spass)
    except (xmlrpclib.Fault,xmlrpclib.ProtocolError), e:
        print "!!! Check Satellite FQDN and login information; You can also look at /var/log/httpd/error_log on the Satellite for more info !!!"
        raise RuntimeError("Login XMLRPC error:\t%s" % e)
    except socket.error, e:
        print "!!! Could not connect to %s" % sserver
        raise RuntimeError("Login socket error:\t%s" % e)
    except:
        raise RuntimeError("Unexpected error:", sys.exc_info()[0])
    return (client, key)


def mergeChannelErrata(client, key, origin_channel, dest_channel):
    """Merge Errata from origin_channel to dest_channel"""
    try:
        resp = client.channel.software.mergeErrata(key, origin_channel, dest_channel)
    except xmlrpclib.Fault, e:
        raise RuntimeError("Errata XMLRPC Fault:\t%s" % e)
    return resp


def mergeChannelPackages(client, key, origin_channel, dest_channel):
    """Merge Pachages from origin_channel to dest_channel"""
    try:
        resp = client.channel.software.mergePackages(key, origin_channel, dest_channel)
    except xmlrpclib.Fault, e:
        raise RuntimeError("Package XMLRPC Fault:\t%s" % e)
    return resp


def updateChannelInfo(client, key, channel_id, newdesc):
    """Update Channel Info in the Satellite DB"""
    try:
        resp = client.channel.software.setDetails(key, channel_id, newdesc)
    except xmlrpclib.Fault, e:
        raise RuntimeError("Info XMLRPC Fault:\t%s" % e)
    return resp


def getChannels(client, key):
    """Return list of channels from Satellite"""
    try:
        resp = client.channel.listAllChannels(key)
    except xmlrpclib.Fault, e:
        raise RuntimeError("Get channel XMLRPC Fault:\t%s" % e)
    return resp


def main():
  global options, args
  env_to_update = []

  ## Exit Codes
  SUCCESS     =  0
  ## Get configuration information
  (sserver, suser, spass) = getConf()
  ## Get satellite server client session
  (client, key) = satLogin(sserver, suser, spass)
  ## Get channel list from satellite
  clist  = getChannels(client, key)
  ## Deal with environment flags
  if options.prod: env_to_update.append("prod")
  if options.qa: env_to_update.append("qa")
  if options.dev: env_to_update.append("dev")
  if env_to_update == []: env_to_update = ["prod", "qa", "dev"]

  ## The Main Event(TM)
  for env in env_to_update:
    for channel in clist:
      if env in channel.get('label'):
        channelinfo = client.channel.software.getDetails(key, channel.get('label'))
        if channelinfo.get('clone_original'):
          cloneinfo = client.channel.software.getDetails(key, channelinfo.get('clone_original'))

          prelease = re.search(r"R20.*$", channelinfo.get('name'))
          if prelease:
            if env in ["prod", "qa"]:
              crelease = re.search(r"R20.*$", cloneinfo.get('name'))
              nrelease = crelease.group(0)
            else:
              prmajor, prminor = prelease.group(0).split('-')
              prdate = time.strptime(prmajor, "R%Y.%m")
              crdate = time.localtime()
              if prdate.tm_year == crdate.tm_year and prdate.tm_mon == crdate.tm_mon:
                prminor = int(prminor) + 1
              else:
                prminor = 1
              nrelease = time.strftime("R%Y.%m") + '-' + str(prminor)
          else:
            print channel.get('label') + ': No release info in channel name: ' + channelinfo.get('name')
            nrelease = False

          print  channel.get('label') + ': Merge Errata/Packages from: ' + cloneinfo.get('label')

          ## Merge Errata
          if not options.debug:
            uperrata = mergeChannelErrata(client, key, cloneinfo.get('label'), channel.get('label'))
            if uperrata:
              print channel.get('label') + ': Merged ' + str(len(uperrata)) + ' Errata.'
            else:
              print channel.get('label') + ': No Errata to merge.'
          else:
            print "Would Sync Errata:   " + channel.get('label') + "  ==>>  " + cloneinfo.get('label')

          ## Merge Packages
          if not options.debug:
            uppackages = mergeChannelPackages(client, key, cloneinfo.get('label'), channel.get('label'))
            if uppackages:
              print channel.get('label') + ': Merged ' + str(len(uppackages)) + ' Packages.'
            else:
              print channel.get('label') + ': No Packages to merge.'
          else:
            print "Would Sync Packages: " + channel.get('label') + "  ==>>  " + cloneinfo.get('label')

          ## Update Channel Info
          if nrelease:
            newdesc = {
              'name': re.sub(prelease.group(0), nrelease, channelinfo.get('name')),
              'description': re.sub(r"Updated.*", time.strftime("Updated %Y%m%d by script"), channelinfo.get('description'))
              }
          else:
            newdesc = {
              'description': re.sub(r"Updated.*", time.strftime("Updated %Y%m%d by script"), channelinfo.get('description'))
              }
          if not options.debug:
            updateChannelInfo(client, key, channel.get('id'), newdesc)
            print channel.get('label') + ': Successfully updated channel info.'
            print newdesc
          else:
            print "Would update info:   " + str(newdesc)
        else:
          print channel.get('label') + ' has no original channel'

        print '******************************';

  try:
    client.auth.logout(key)
  except xmlrpclib.Fault, e:
    raise RuntimeError("Logout XMLRPC Fault:\t%s" % e)

  return SUCCESS

### END OF main() ###

if __name__ == "__main__":
    retval = 1
    try:
        start_time = time.time()
        parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), 
                                       usage=globals()['__doc__'], 
                                       version=globals()['__version__'])
        parser.add_option('-d', '--debug', help='Debug mode',
                          dest='debug', action='store_true', default=False)
        parser.add_option('--dev',  help='Update Development Channels',
                          dest='dev', action='store_true', default=False)
        parser.add_option('--qa',   help='Update Q/A Channels',
                          dest='qa', action='store_true', default=False)
        parser.add_option('--prod', help='Update Production Channels',
                          dest='prod', action='store_true', default=False)
        (options, args) = parser.parse_args()
        #if len(args) < 1:
        #    parser.error ('missing argument')
        if options.debug: print time.asctime()
        retval = main()
        if options.debug: 
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
