#!/usr/bin/env ruby
##
## Written by: Matthew Lee Hinman
## lee [at] writequit [dot] org
## http://writequit.org
## Grabs Yahoo messages out of a pcap live stream or file
##
## Usage: ./yahsnarf -i <dev> or ./yahsnarf -r <pcap_file>
#
# Requires bit-struct:
# http://redshift.sourceforge.net/bit-struct/
#
# and ruby-pcap:
# http://www.goto.info.waseda.ac.jp/~fukusima/ruby/pcap-e.html
#
##

# Library for pcap reading
require 'pcaplet'
include Pcap
# Libray for struct -> class mapping
require 'bit-struct'


# Encapsulation class for a Yahoo Message Packet
class YahooPacket < BitStruct
  text      :ymsg,    32,  "Yahoo MSG protocol"
  unsigned  :version, 16,  "Version"
  padding   :p1,      16
  unsigned  :length,  16,  "Packet length"
  unsigned  :service, 16,  "Service"
  unsigned  :status,  32,  "Status"
  unsigned  :sessid,  32,  "Session ID"
  rest      :content,     "Content"
end

# Class for decoding a Yahoo packet
class YahooPacketDecoder
  def initialize(p)
    @pkt = p
    @data = p.tcp_data
  end

  def decode_packet
    # Here's where the magic happens
    p = YahooPacket.new(@data)

    # If it's not a YMSG and service 6 (message), ignore it
    return unless (p.ymsg=="YMSG" and p.service==6)

    # Debugging output
    #puts p.inspect_detailed 

    d = decode_content(p.content)
    
    if d.nil?
      puts "Unable to decode content"
      return
    end

    # The escape sequence is to get rid of color
    puts "\033[0m#{ d['src'] } --> #{ d['dst'] }: #{ d['msg'].chomp }"
  end

  private
  def decode_content(c)
    res = {}
    c = c.split("\300\200")
    i = 0
    c.each { |k|
      i = i + 1
      next if (i % 2 == 0)
      if k.to_i == 1
        res['src'] = c[i] unless res.has_key?('src')
      elsif k.to_i == 5
        res['dst'] = c[i] unless res.has_key?('dst')
      elsif k.to_i == 14
        c[i] = c[i].gsub(/"/,"'")
        res['msg'] = c[i] unless res.has_key?('msg')
        return res
      end
    }
    return nil
  end

end


## The actual main part of the program
STDERR.puts "Use '-h' to display usage"
pcaplet = Pcaplet.new("-n -s 65536")
STDERR.puts "Capture/Decoding..."

## Filter, all Yahoo message traffic runs on 5190
YAHOO_DATA  = Pcap::Filter.new('tcp and port 5050', pcaplet.capture)
pcaplet.add_filter(YAHOO_DATA)

pcaplet.each_packet { |pkt|
  yp = YahooPacketDecoder.new(pkt)

  yp.decode_packet()
}
pcaplet.close

