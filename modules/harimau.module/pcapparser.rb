# FLOWTAG - parses and visualizes pcap data
# Copyright (C) 2007 Christopher Lee
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Lesser GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Lesser GNU General Public License for more details.
# 
# You should have received a copy of the Lesser GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class PcapParser
  LINKTYPE_ETH = 0x0001
  LINKTYPE_SLL = 0x0071
  
  def initialize(pcapfh)
    @offset = 0
    @bigendian = nil
    @fh = pcapfh
    @fh.seek 0
    magic = @fh.read(4).unpack("N")[0]
    @bigendian = (magic == 0xa1b2c3d4) ? true : false
    endian = (@bigendian) ? "nnNNNN" : "vvVVVV"
    @version_major, @version_minor, @zone, @significant_figures, @snaplength, @linktype = @fh.read(20).unpack(endian)
    @offset += 24
    if @linktype != LINKTYPE_ETH
      puts "Only ethernet is supported, sorry."
      exit
    end
  end
  
  def nextpkt
    endian = (@bigendian) ? "NNNN" : "VVVV"
    pkt = {}
    tv_sec, tv_usec, caplen, origlen = @fh.read(16).unpack(endian)
    time = tv_sec + (tv_usec / 1E6)
    data = @fh.read(caplen)
    @offset += 16+caplen
    return Packet.new(time, data)
  end
  
  def each
    while ! @fh.eof?
      yield nextpkt
    end
  end

  def close
    @fh.close unless @fh.tty?
  end
end

class Packet
  attr_reader :time, :data, :ip_src, :ip_dst, :sport, :dport, :tcp_sport, :tcp_dport, :udp_sport, :udp_dport, :length
  def initialize(time, data)
    @time = time
    @data = data
    @length = data.length
    @ip = @tcp = @udp = false
    @ip_src = @ip_dst = @sport = @dport = @tcp_sport = @tcp_dport = @udp_sport = @udp_dport = nil
    @ip = (data[12,2].unpack("n")[0] == 0x0800) ? true : false
    offset = 14
    if @ip
      @ip_hlen = (data[offset] & 0x0f) << 2
      @ip_proto = data[offset+9]
      @ip_src, @ip_dst = data[offset+12,8].unpack("NN")
      offset += @ip_hlen
      @tcp = true if @ip_proto == 0x06
      @udp = true if @ip_proto == 0x11
      if @tcp
        @sport, @dport = data[offset,4].unpack("nn")
        @tcp_sport = @sport
        @tcp_dport = @dport
        @tcp_hlen = (data[offset+12]>>4)<<2
        offset += @tcp_hlen
      elsif @udp
        @sport, @dport = data[offset,4].unpack("nn")
        @udp_sport = @sport
        @udp_dport = @dport
        offset += 8
      end
    end
    @data_offset = offset
  end
  
  def ip?
    @ip
  end
  
  def udp?
    @udp
  end
  
  def tcp?
    @tcp
  end
  
  def payload
    @data[@data_offset,10000]
  end
end