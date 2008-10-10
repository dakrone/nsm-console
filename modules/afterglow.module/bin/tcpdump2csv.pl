#!/usr/bin/perl
#
# Copyright (c) 2006 by Raffael Marty
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Title: 	TCPdump 2 CSV
#
# File: 	tcpdump2csv.pl
#
# Version: 	1.5
#
# Description:	Takes a tcpdump pcap file and parses it into a csv output.
#
# Usage:	tcpdump -vttttnnelr /tmp/log.tcpdump | ./tcpdump2csv.pl ["field list"]
#
# Running in conjunction with afterglow:
# 		tcpdump -vttttnnelr /tmp/log.tcpdump | ./tcpdump2csv.pl "sip dip sport" | 
# 		perl ../graph/afterglow.pl | neato -Tgif -o test.gif
#
# Possible fields:
# 		timestamp  dip  sip  ttl  tos  id  offset  flags  len  
# 		sourcemac  destmac  ipflags  sport  dport
#
# Known Issues:
# 		Does not parse ARP packets
#		Does not parse SAP packets
#		Does not parse multi-line DNS packets
#
#		ATTENTION: SHOULD work with tcpdump 3.8.x
#		ATTENTION: ONLY works with tcpdump 3.9.x
#			
# URL:		http://afterglow.sourceforge.net
#
# Changes:	
# 
# 06/13/05	Initial Version by ram
# 06/25/05	ram's birthday: taking care of source and target swapping 
# 		Server: receives a SYN or sends a SYN ACK
# 		If no SYN or SYN ACK seen for a connection, assume the machine with
# 		port < 1024 is the server
# 12/17/05	Fixing error handling. Should not exit when an unknown packet arrives
# 		Also introducing the $DEBUG variable
# 05/24/06	Version 1.5:
# 		Changing the parsing to support tcpdump 3.9.4. Rewrote parsing 
# 		part to be a bit more sane ;)
#
###############################################################################/

use strict vars;



my $output=$ARGV[0] || "full";

my $DEBUG=0;

our ($timestamp,$etherproto,$dip,$sip,$ttl,$tos,$id,$offset,$flags,$len,$sourcemac,$destmac,$ipflags,$sport,$dport,$proto,$rest, $dnshostresponse, $dnslookup, $dnsipresponse, $dnstype, $dnslookup);

our %clientServerConn;

while (<STDIN>) {
	chomp;

	# tcpdump 3.9.4 : 2006-05-14 11:05:58.683193 00:05:4e:44:b7:25 > 00:01:4e:00:b6:59, ethertype IPv4 (0x0800), length 54: (tos 0x0, ttl  64, id 6321, offset 0, flags [DF], proto: TCP (6), length: 40) 10.69.69.13.1555 > 10.69.69.20.52912: R, cksum 0x6c1c (correct), 0:0(0) ack 368294482 win 0
	# 2006-05-23 08:15:39.809918 00:05:4e:44:b7:25 > 00:50:59:85:1b:60, ethertype IPv4 (0x0800), length 85: (tos 0x0, ttl  64, id 49494, offset 0, flags [DF], proto: UDP (17), length: 71) 10.149.3.174.35837 > 206.13.29.12.53:  19302+ A? 02.presence.userplane.com. (43)
	# 2006-05-15 xxx 00:05:4e:44:b7:25 > 00:50:59:85:1b:60, ethertype IPv4 (0x0800), length 80: (tos 0x0, ttl  64, id 38402, offset 0, flags [DF], proto: UDP (17), length: 66) 10.149.3.174.35843 > 206.13.29.12.53:  25351+ AAAA? webmail.arcsight.com. (38)

	# 2006-05-15 xxx 00:50:59:85:1b:60 > 00:05:4e:44:b7:25, ethertype IPv4 (0x0800), length 101: (tos 0x60, ttl 123, id 16394, offset 0, flags [none], proto: UDP (17), length: 87) 206.13.29.12.53 > 10.149.3.174.35843:  29873 1/0/0 02.presence.userplane.com. A 8.3.208.204 (59)

		if (/(\d+-\d+-\d+ \d+:\d+:\d+\.\d+) (\S+) > (\S+), ethertype (\S+) \(\S+\), length:? (\d+):? (?:\S+ )?\((?:tos +(\S+), )?(?:ttl +(\d+), )?(?:id +(\d+), )?(?:offset +(\d+), )?(?:flags \[(\S+)\], )?(?:proto: (\S+).*?, )?(?:length: (\d+))?.*?\) (\S+?)(?:\.(\d+))? > (\S+?)(?:\.(\d+))?: +(?:(\S+),? (.*?)|\d+[\+\*\-]* \d+\/\d+\/\d+ (\S+) (\S+) (\S+) .*?|\d+[\+\*\-]* (\S+) (\S+) .*?)?/ )  {

		$timestamp = $1 || "";
		$sourcemac = $2 || "";
		$destmac = $3 || "";
		$etherproto = $4 || "";
		$len = $5 || "";
		$tos = $6 || "";
		$ttl = $7 || "";
		$id = $8 || "";
		$offset = $9 || "";
		$ipflags = $10 || "";
		$proto = $11 || "";
		$len = $12 || "";
		$sip = $13 || "";
		$sport = $14 || "";
		$dip = $15 || "";
		$dport = $16 || "";
		$flags = $17 || "";
		$rest = $18 || "";
		$dnshostresponse = $20 || "";
		$dnslookup = $21 || "";
		$dnsipresponse = $22 || "";
		$dnstype = $23 || "";
		$dnslookup = $24 || $dnslookup;

		# skip 802.3 packets:
		next if ($etherproto eq "802.3,");
		# skip ARP
		next if ($etherproto eq "ARP");

		$timestamp =~ s/(.*?)\.\d+$/\1/;
		$sourcemac =~ s/,$//;
		$destmac =~ s/,$//;
		$len =~ s/:$//;

	} else {

		$DEBUG && print STDERR "ERROR: $_\n";
		next;

	}

	my @fields = split (" ",$_);

	# adding ACK flag as an "A"
	if ($_ =~ / ack /) { $flags .= "A"; }

	my $connId = $sip.$dip.$sport.$dport;
	my $reverseConnId = $dip.$sip.$dport.$sport;

	# trying to find the client and the server and the act opon that
	if ($flags =~ /S.*A/) {		# server to client

		$clientServerConn{$reverseConnId}="1";
		# swap source and dest:
		($sourcemac,$destmac) = ($destmac,$sourcemac);
		($sip,$dip) = ($dip,$sip);
		($sport,$dport) = ($dport,$sport);

	} elsif ($flags =~ /S/) {	# client to server

		$clientServerConn{$connId}="1";

	} elsif ($clientServerConn{$reverseConnId}) {

		# swap source and dest:
		($sourcemac,$destmac) = ($destmac,$sourcemac);
		($sip,$dip) = ($dip,$sip);
		($sport,$dport) = ($dport,$sport);

	} elsif ((!$clientServerConn{$reverseConnId}) && (!$clientServerConn{$connId}) && ($proto eq "tcp")) {

		# we never saw a SYN or a SYN ACK and we are in TCP, let us try the port numbers
		# This is better than not doing it :)

		if (($sport < 1024) && ($dport > 1024)) {
			$clientServerConn{$reverseConnId}="1";
			# swap source and dest:
			($sourcemac,$destmac) = ($destmac,$sourcemac);
			($sip,$dip) = ($dip,$sip);
			($sport,$dport) = ($dport,$sport);
		}

	}
	
	if ($output eq "full") {
		print "$timestamp $sourcemac $destmac $sip $dip $sport $dport $flags $len $proto $ttl $id $offset $tos $ipflags\n";
	} else {
		my @tokens = split / /,$output;
		print ${shift(@tokens)};
		for my $token (@tokens) {
			if (!defined($$token)) {
				$DEBUG && print STDERR "$token is not a known field\n";
				#exit;
			} else {
				print ','.$$token;
			}
		}
		print "\n";
	}
	
}

# To verify:
# tcpdump 3.8.x : 2002-08-24 05:34:18.634488 00:00:0c:04:b2:33 > 00:03:e3:d9:26:c0, ethertype IPv4 (0x0800), length 223: IP (tos 0x0, ttl 122, id 544, offset 0, flags [DF], length: 209, bad cksum ff6b (->14ac)!) 138.97.18.88.61924 > 64.4.12.158.1863: P [bad tcp cksum 6c66 (->aca6)!] 9384:9553(169) ack 9641 win 17390
# tcpdump 3.8.x : 2002-08-24 10:52:42.184488 00:03:e3:d9:26:c0 > 00:00:0c:04:b2:33, ethertype IPv4 (0x0800), length 60: IP (tos 0x0, ttl 232, id 0, offset 8896, flags [+, DF], length: 40, bad cksum ff99 (->b4d9)!) 192.9.100.88 > 138.97.10.219: tcp

# 2006-05-23 08:15:39.809918 00:50:59:85:1b:60 > 00:12:f0:b1:c7:c6, ethertype ARP (0x0806), length 64: arp reply 10.149.0.1 is-at 00:50:59:85:1b:60
# 2006-05-23 08:54:58.278518 00:50:59:85:1b:60 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 64: arp who-has 10.149.3.187 tell 10.149.3.250
	# 2006-05-23 08:15:35.985245 00:50:59:85:1b:60 > 00:40:96:a3:5f:58, ethertype IPv4 (0x0800), length 110: (tos 0x60, ttl  49, id 14118, offset 0, flags [none], proto: UDP (17), length: 96) 216.191.40.60.500 > 10.149.3.139.3210: isakmp 1.0 msgid : phase 2/others ? inf[E]: [encrypted hash]



# To be done: (need to get the 3.9.x output for these!
# 2005-01-12 14:38:20.660616 00:0d:56:e3:44:33 > 33:33:00:00:00:02, ethertype IPv6 (0x86dd), length 70: fe80::20d:56ff:fee3:4433 > ff02::2: [icmp6 sum ok] icmp6: router solicitation (src lladdr: 00:0d:56:e3:44:33) (len 16, hlim 255)
# 2005-05-03 18:42:31.274438 00:0d:56:74:c4:d9 > ff:ff:ff:ff:ff:ff, 802.3, length 94: LLC, dsap Global (0xff), ssap Global (0xff), cmd 0x00, (NOV-802.3) 00000000.00:0d:56:74:c4:d9.0455 > 00000000.ff:ff:ff:ff:ff:ff.0455: ipx-netbios 50
# 2005-09-08 16:38:14.906293 00:14:69:1f:b3:00 > 01:00:0c:cc:cc:cc, 802.3, length 338: LLC, dsap SNAP (0xaa), ssap SNAP (0xaa), cmd 0x03, CDPv2, ttl: 180s, checksum: 692 (unverified), length 316
# 2005-09-08 16:38:11.013187 00:03:93:ea:dc:2f > 33:33:ff:ea:dc:2f, ethertype IPv6 (0x86dd), length 86: fe80::203:93ff:feea:dc2f > ff02::1:ffea:dc2f: HBH (padn)(rtalert: 0x0000) [icmp6 sum ok] icmp6: multicast listener report max resp delay: 0 addr: ff02::1:ffea:dc2f [hlim 1] (len 32)
# 2005-09-08 16:38:08.146159 00:03:93:ea:dc:2f > 33:33:00:00:00:02, ethertype IPv6 (0x86dd), length 86: fe80::203:93ff:feea:dc2f > ff02::2: HBH (padn)(rtalert: 0x0000) [icmp6 sum ok] icmp6: multicast listener done max resp delay: 0 addr: ff02::fb [hlim 1] (len 32)
# 2005-09-08 16:38:05.896611 00:03:93:ea:dc:2f > 33:33:00:00:00:fb, ethertype IPv6 (0x86dd), length 459: fe80::203:93ff:feea:dc2f.5353 > ff02::fb.5353: [udp sum ok]  0 [8q] [8n] ANY? Altair._ftp._tcp.local. ANY? Altair [00:03:93:d5:81:02]._workstation._tcp.local. ANY? Altair._ssh._tcp.local. ANY? Altair._sftp-ssh._tcp.local. ANY? Ari Serim._http._tcp.local. ANY? AriM-bM-^@M-^Ys Beats._daap._tcp.local. ANY? iTunes_Ctrl_AE2BB3BEAAAB7A8B._dacp._tcp.local. ANY? Altair.local. (397) (len 405, hlim 255)
# 2005-09-08 16:38:05.696393 00:03:93:ea:dc:2f > 33:33:00:00:00:fb, ethertype IPv6 (0x86dd), length 349: fe80::203:93ff:feea:dc2f.5353 > ff02::fb.5353: [udp sum ok]  0*- [0q] 8/0/0 _services._dns-sd._udp.local. PTR _ftp._tcp.local., _services._dns-sd._udp.local. PTR _workstation._tcp.local., _services._dns-sd._udp.local. PTR _ssh._tcp.local., _services._dns-sd._udp.local. PTR _sftp-ssh._tcp.local., _services._dns-sd._udp.local. PTR _http._tcp.local., _services._dns-sd._udp.local. PTR _daap._tcp.local., _services._dns-sd._udp.local. PTR _dacp._tcp.local., F.2.C.D.A.E.E.F.F.F.3.9.3.0.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.E.F.ip6.arpa. (Cache flush) PTR Altair.local. (287) (len 295, hlim 255)



