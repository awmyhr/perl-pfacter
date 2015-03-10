---
title: perl-facter
description: Perl mod for collecting OS facts
author: awmyhr
tags: perl, puppet
created:  2014 Jun 09
modified: 2014 Jun 09

---

perl-facter
=========

### Perl mod for collecting OS facts

pfacter is a Perl module for collecting Puppet-compatible OS facts. It has basic
support for AIX, Darwin, FreeBSD, Linux, Solaris and SCO UNIX. The goal is to
collect as many Puppet facts as possible without relying on any non-standard
installations. Ideally the only requirement beyond base-OS should be Perl.

***See the [changelog] for what's new in the most recent release.***

### Lineage

This project is forked from [Scott Schneider](https://github.com/sschneid/perl-pfacter).
Over time I will integrate code from my old [SysInfo.pm](https://github.com/awmyhr/SATools/blob/master/lib/SysInfo.pm) project
This was done as I have SCO servers I need to support which are unable to run 
puppet-agent.

### The original README file

Here is the entire contents of the original README file:

>pfacter is a collection of perl scripts used to collect and display facts
>about an operating system.  It is freely distributable under the terms of
>the GNU General Public License.

