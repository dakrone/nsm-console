# vim: set ts=2 sw=2 tw=80
## Write a range of packet payloads into STDOUT
# filename - Name of the file to read from
# start_pkt - Packet # to start from
# end_pkt - Packet # to stop at (or * for all)
# fullpacket - Boolean whether to print full packet or just payload
def print_pkt_range(filename,start_pkt,end_pkt,opts,fullpacket)
  puts "Filename: #{filename}"
  puts "#{opts} from #{start_pkt} to #{end_pkt}"

  begin
    pp = PcapParser.new(File.new(filename))
    pktnum = 0
    pp.each { |pkt|
      pktnum += 1
      next if pktnum < start_pkt
      unless end_pkt == "*"
        return if pktnum > end_pkt
      end
      print "#{pktnum} "
      res = print_pkt_payload(pkt,opts,fullpacket)
      return if !res
    }
  rescue Interrupt
    puts "Stopped by ^C"
    return
  rescue
    STDERR.puts "Exception: #{$!}"
    STDERR.puts $!.backtrace
  end
end

## Given a Packet, print the payload
def print_pkt_payload(p,opts,fullpacket)
  begin
    print "#{p.time} "
    if p.ip?
      print [p.ip_src].pack("N").unpack("C4").join(".")
      print " -> "
      print [p.ip_dst].pack("N").unpack("C4").join(".")
      print " TCP " if p.tcp?
      print " UDP " if p.udp?
      print " IP " if p.ip? and not p.tcp? and not p.udp?
      print "#{p.sport} > "
      print "#{p.dport} "
      print "[#{p.readable_flags}] " if p.tcp?
      print "Len=#{p.length}"

      # If the full packet is requested, print all the data, not just
      # the payload
      if fullpacket
        data = p.data.unpack('H*').to_s
      else
        data = p.payload.unpack('H*').to_s
      end
      
      if opts == "full"
        offset = 16
        #data.scan(/................................/).each { |line|
        data.scan(/.{2,32}/).each { |line|
          print "\n "
          offsethex = offset.to_s(base=16)
          print "0" * (4 - offsethex.length)
          print offsethex
          print "  "

          spaces = 6
          ## Print hex
          line.scan(/../).each { |byte|
            print byte
            print " "
            spaces += 3
          }

          print " "
          spaces += 2
          # make up extra padding if it isn't an entire line
          if line.length < 32
            print " " * (56 - spaces)
          end

          ## Print ascii
          line.scan(/../).each { |byte|
            if (byte.to_i(16) > 32) and (byte.to_i(16) < 127)
              print byte.hex.chr
            else
              print "."
            end
          }
          offset += 16
        }
        print "\n"
      elsif opts == "hex"
        print "\n"
        #data = p.payload.unpack('H*').to_s
        print data
        print "\n"
      elsif opts == "ascii"
        print "\n"
        #data = p.payload.unpack('H*').to_s
        data.scan(/../).each { |byte|
          if (byte.to_i(16) > 32) and (byte.to_i(16) < 127)
            print byte.hex.chr
          else
            print "."
          end
        }
        print "\n"
      end

    else
      print "[unsupported protocol] "
      print "Len=#{p.length}"
    end
    print "\n"
  rescue Interrupt
    puts "Stopped by ^C"
    return false
  rescue
    STDERR.puts "Exception: #{$!}"
  end
  return true
end

## Write a range of packet payloads into a file
def rawwrite_pkt_range(file,min,max,outputfile,fulldump)
  puts "Writing (append) packet(s) #{min} through #{max} from #{file} to #{outputfile}..."
  begin
    pp = PcapParser.new(File.new(file))
    pktnum = 0
    pp.each { |pkt|
      pktnum += 1
      next if pktnum < min.to_i
      unless max == "*"
        return if pktnum > max.to_i
      end
      #print "#{pktnum} "
      res = rawwrite_pkt_payload(pkt,outputfile,pktnum,fulldump)
      return if !res
    }
  rescue Interrupt
    puts "Writing aborted!"
    return
  rescue
    STDERR.puts "Exception: #{$!}"
  end
end

## Given a Packet, write the payload into 'file'
def rawwrite_pkt_payload(p,file,num,fulldump)
  begin
    if p.ip?
      if fulldump
        data = p.data.unpack('H*').to_s
        strdata = data
      else
        data = p.payload.unpack('H*').to_s
        strdata = Encoder.decode_hex(data)
      end
      #strdata = Encoder.decode_hex(data)
      f = File.open(file, File::WRONLY|File::APPEND|File::CREAT)
      f.write(strdata)
      f.close
    else
      puts "packet #{num} skipped because of unsupported protocol"
    end
  rescue Interrupt
    puts "Writing aborted!!"
    return false
  rescue
    STDERR.puts "Exception: #{$!}"
  end
  return true
  
end
