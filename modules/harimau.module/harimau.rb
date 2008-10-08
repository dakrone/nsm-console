#!/usr/bin/env ruby
## Copyright 2008 Matthew Lee Hinman
## Read a pcap file, query the Harimau list and display output

require 'pcapparser'

file = ARGV[0]
if file.nil?
  puts "Please specify a filename"
  exit(0)
end

$ipaddr = {}

$wgetinstalled = false
$wgetinstalled = system("which wget 2>&1 > /dev/null")
if !$wgetinstalled
  require 'net/http'
end

def print_harimau(addr)
  return if !$ipaddr[addr].nil?
  
  $ipaddr[addr] = 1 ## So it's not nil any more
  addr = [addr.to_i].pack("N").unpack("C4").join(".")
  truncaddr = String.new(addr)
  truncaddr =~ /(\d{1,3}\.\d{1,3}\.\d{1,3})\./
  truncaddr = String.new($1)
  if $wgetinstalled
    out = `wget -q -O - http://watchlist.security.org.my/watchlist/show?ip=#{addr} | grep '#{truncaddr}'`
    if out.length < 1
      puts "#{addr}: No records"
    else
      puts out.chomp
    end
  else 
    url = URI.parse("http://watchlist.security.org.my/watchlist/show?ip=#{addr}")
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    found = false
    res.body.each_line { |line|
      if line =~ /#{truncaddr}/i
        puts line.chomp
        found = true
      end
    }
    if found == false
      puts "#{addr}: No records found"
    end
  end
end

pp = PcapParser.new(File.new(file))
pp.each { |pkt|
  print_harimau(pkt.ip_src.to_s)
  print_harimau(pkt.ip_dst.to_s)
}
