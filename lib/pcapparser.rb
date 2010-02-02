# DESCRIPTION: is part of the flowtag toolkit and simply parses a pcap file.
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
  LINKTYPE_ETH  = 0x0001
  LINKTYPE_NULL = 0x0000
  LINKTYPE_SLL  = 0x0071
  
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
    if (@linktype != LINKTYPE_ETH) && (@linktype != LINKTYPE_NULL)
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
    return Packet.new(time, data, @linktype)
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
  LINKTYPE_ETH = 0x0001
  LINKTYPE_NULL = 0x0000

  attr_reader :time, :data, :ip_src, :ip_dst, :sport, :dport, :tcp_sport, :tcp_dport, :udp_sport, :udp_dport, :length, :seq_num, :ack_num
  def initialize(time, data, linktype)
    @time = time
    @data = data
    @length = data.length
    @ip = @tcp = @udp = false
    @ip_src = @ip_dst = @sport = @dport = @tcp_sport = @tcp_dport = @udp_sport = @udp_dport = @seq_num = @ack_num = nil
    if linktype == LINKTYPE_ETH
      @ip = (data[12,2].unpack("n")[0] == 0x0800) ? true : false
      offset = 14
    elsif linktype == LINKTYPE_NULL
      @ip = (data[2,2].unpack("n")[0] == 0x0000) ? true : false
      offset = 4
    end
    if @ip
      @ip_hlen = (data[offset].ord & 0x0f) << 2
      @ip_proto = data[offset+9].ord
      @ip_src, @ip_dst = data[offset+12,8].unpack("NN")
      offset += @ip_hlen
      @tcp = true if @ip_proto == 0x06
      @udp = true if @ip_proto == 0x11
      if @tcp
        @sport, @dport = data[offset,4].unpack("nn")
        @tcp_sport = @sport
        @tcp_dport = @dport
        ## Modifications made by MLH for seq/ack numbers
        @seq_num = data[offset+4,4].unpack("nn").to_s.to_i
        @ack_num = data[offset+8,4].unpack("nn").to_s.to_i

        ## Determine TCP flags
        @flags = data[offset+13].ord.to_s
        @urg, @ack, @psh, @rst, @syn, @fin = parse_flags(@flags)

        @tcp_hlen = (data[offset+12].ord>>4)<<2
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

  ## Definitions for accessors, since they are boolean
  def urg_set?
    @urg
  end
  def ack_set?
    @ack
  end
  def psh_set?
    @psh
  end
  def rst_set?
    @rst
  end
  def syn_set?
    @syn
  end
  def fin_set?
    @fin
  end

  def parse_flags(flags)
    ## Bitwise AND to get the flag we care about
    flags = flags.to_s.to_i
    urg = (flags & 0x20) > 0 ? true : false 
    ack = (flags & 0x10) > 0 ? true : false 
    psh = (flags & 0x8) > 0 ? true : false 
    rst = (flags & 0x4) > 0 ? true : false 
    syn = (flags & 0x2) > 0 ? true : false 
    fin = (flags & 0x1) > 0 ? true : false 
    return urg, ack, psh, rst, syn, fin
  end

  def flags
    ## Return just the basic flags
    return (@flags.to_i & 0x3f)
  end
  
  def readable_flags
    ## Flags in format: ...... <--> UAPRSF, ex: .A..S.F
    st = ""
    st = st + (@urg ? "U" : ".")
    st = st + (@ack ? "A" : ".")
    st = st + (@psh ? "P" : ".")
    st = st + (@rst ? "R" : ".")
    st = st + (@syn ? "S" : ".")
    st = st + (@fin ? "F" : ".")
    return st
  end

  def payload
    @data[@data_offset,10000]
  end
end
