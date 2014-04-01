#!/usr/bin/perl -w
# Copyright (C) 2011 Ben McClelland
#
# Unless otherwise indicated, this information has been authored by an employee
# or employees of the Los Alamos National Security, LLC (LANS), operator of the
# Los Alamos National Laboratory under Contract No.  DE-AC52-06NA25396 with the
# U.S. Department of Energy.  The U.S. Government has rights to use, reproduce,
# and distribute this information. The public may copy and use this information
# without charge, provided that this Notice and any statement of authorship are
# reproduced on all copies. Neither the Government nor LANS makes any warranty,
# express or implied, or assumes any liability or responsibility for the use of
# this information.
#
# This program has been approved for release from LANS by LA-CC Number 10-066,
# being part of the HPC Operational Suite.

use strict;
use File::Path;
use Sys::Syslog qw(:standard :macros);    # standard functions, plus macros
use Fcntl qw(:DEFAULT :flock);

BEGIN {
    require "/etc/perceus/Perceus_Include.pm";
    push(@INC, "$Perceus_Include::libdir");
}

use Perceus::Nodes;
use Perceus::DB;
use Perceus::Sanity;
use Perceus::Util;
use Perceus::Config;

my $CONFIG = "/etc/perceus/nodes.conf";

my %db              = ();
my $added_name      = ();
my %defaults        = &parse_config("/etc/perceus/defaults.conf");
my @databases       = &list_databases();

sysopen(LOCKFILE, "/tmp/.node_add.lock", O_RDONLY|O_CREAT);
flock(LOCKFILE, LOCK_EX);

foreach my $db ( @databases ) {
    rmtree("$Perceus_Include::database/$db.bdb", { verbose => 0, mode => 0711 });
}

&check_database(@Perceus::DB::DB_Files);

@databases = &list_databases();

sub ip2num {
    return(unpack("N",pack("C4",split(/\./,$_[0]))));
}

openlog("reload_perceus", 'pid', 'user');

foreach my $db ( @databases ) {
    $db{"$db"} = &opendb($db, O_RDWR);
}

if (open(CONFFILE, "$CONFIG")) {
    while(<CONFFILE>) {
        next if /^s*($|#)/;
		     
	my($id, $nodeid, $group, $vnfs, $ip) = /^\s*(\S+)\s+(.{17})\s+(\S+)\s+(\S+)\s+(\S+)/  or syslog(LOG_INFO, "Syntax error: $_");
	
	unless ( $nodeid =~ /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i ) {
	    syslog(LOG_INFO, "$id: $nodeid must be in the form of a 6 field MAC address");
	    next;
	}
	
	# Only match against proper MAC/HW addresses. The first byte is used to
	# define the string, and "01" is the hardware address. The second field
	# is always "00".
	if ( $nodeid =~ /^(01:)?([0-9a-z]{2}:){5}[0-9a-z]{2}$/i ) {
	    
	    # As mentioned above, remove the MAC address type identifier if it
	    # exists.
	    $nodeid =~ s/^01://g; $nodeid = uc($nodeid);
	    
	    foreach my $db ( @databases ) {
		if ( $db eq "hostname" ) {
		    $db{"$db"}->set($nodeid, $id);
		} elsif ( $db eq "group" ) {
		    $db{"$db"}->set($nodeid, $group);
		} elsif ( $db eq "ipaddr" ) {
		    $db{"$db"}->set($nodeid, $ip);
		} elsif ( $db eq "vnfs" ) {
		    $db{"$db"}->set($nodeid, $vnfs);
		} elsif ( $db eq "enabled" ) {
		    $db{"$db"}->set($nodeid, $defaults{"Enabled"}[0]);
		} elsif ( $db eq "debug" ) {
		    $db{"$db"}->set($nodeid, $defaults{"Debug"}[0]);
		} else {
		    $db{"$db"}->set($nodeid, undef);
		}
	    }

	} else {
	    &eprint("You must define the Node's ID (MAC/HW address format) to add the node!");
	}
	
	syslog('notice', "Successfully inserted node $id ($nodeid)");
    }
}
&write_ethers($db{"hostname"});

foreach my $db ( @databases ) {
    $db{"$db"}->closedb();
}
flock(LOCKFILE, LOCK_UN);
close(LOCKFILE);

closelog;
