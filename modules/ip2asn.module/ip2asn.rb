#!/usr/bin/env ruby

require 'pcapparser.rb'
require 'socket'


pp = PcapParser.new(File.new(ARGV[0]))

addrs = {}

STDERR.print "Gathering addresses..."
pp.each { |pkt|

  if addrs.has_key?(pkt.ip_src)
    addrs[pkt.ip_src] = addrs[pkt.ip_src] + 1
  else
    addrs[pkt.ip_src] = 1
  end

  if addrs.has_key?(pkt.ip_dst)
    addrs[pkt.ip_dst] = addrs[pkt.ip_dst] + 1
  else
    addrs[pkt.ip_dst] = 1
  end
}
STDERR.print "done.\n"

STDERR.print "Querying addresses..."
begin
  s = TCPSocket.new('whois.cymru.com',43)
  s.write("begin\n")
  addrs.each { |k,v|
    next if k.nil?

    # Use the cymru team's ip->asn server
    ip = ""
    ip = [k].pack("N").unpack("C4").join(".")
#    STDERR.puts ip
    s.write(ip)
    s.write("\n")

  }
  s.write("end\n")
  print "\n"
  while line = s.gets
    print line
  end
  s.close
rescue
  STDERR.puts "Encountered error: #{$!}"
end
STDERR.puts "done.\n"

