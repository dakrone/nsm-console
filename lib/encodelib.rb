# vim: set ts=2 sw=2 tw=80
## Class encapsulating all the encode/decode methods
class Encoder
  def Encoder.get_encode_list
    ["base64","md5","sha256","urlescape","binary","binary_MSB","binary_LSB","hex","hex_MSB","hex_LSB","uuencode","rot13"]
  end
  def Encoder.get_decode_list
    ["base64","urlescape","binary","binary_MSB","binary_LSB","hex","char","uudecode","octal","rot13"]
  end

  ## Encoder methods
  def Encoder.encode_base64(str)
    require 'base64'
    return Base64.encode64(str)
  end

  def Encoder.encode_md5(str)
    require 'digest/md5'
    return Digest::MD5.hexdigest(str)
  end

  def Encoder.encode_sha256(str)
    require 'digest/sha2'
    return Digest::SHA256.hexdigest(str)
  end

  def Encoder.encode_urlescape(str)
    require 'cgi'
    return CGI.escape(str)
  end
  
  def Encoder.encode_binary(str)
    return str.unpack('B*').to_s
  end
  def Encoder.encode_binary_MSB(str)
    return str.unpack('B*').to_s
  end
  def Encoder.encode_binary_LSB(str)
    return str.unpack('b*').to_s
  end
  
  # Note that the default "hex" encoding is little-endian, if you're using
  # NSM-Console on SPARC or PPC, uhhh...
  def Encoder.encode_hex(str)
    return str.unpack('H*').to_s
  end
  def Encoder.encode_hex_LSB(str)
    return str.unpack('h*').to_s
  end
  def Encoder.encode_hex_MSB(str)
    return str.unpack('H*').to_s
  end
  
  def Encoder.encode_uuencode(str)
    return [str].pack('u*').to_s
  end
  
  def Encoder.encode_rot13(str)
    return str.downcase.rot13
  end
  
  ## Decoder methods
  def Encoder.decode_base64(str)
    require 'base64'
    return Base64.decode64(str)
  end

  def Encoder.decode_urlescape(str)
    require 'cgi'
    return CGI.unescape(str)
  end
  
  def Encoder.decode_binary(str)
    return str.to_a.pack('B*')
  end
  def Encoder.decode_binary_MSB(str)
    return str.to_a.pack('B*')
  end
  def Encoder.decode_binary_LSB(str)
    return str.to_a.pack('b*')
  end
  
  def Encoder.decode_hex(str)
    out = ""
    # Check for space-delineated and kill the spaces if it is
    if str =~ / /
      str.delete!(" ")
    end

    # Here I do some fancy checking to make sure that the string isn't already
    # delineated by \x, which would automatically translate the string in ruby
    str.scan(/../).each { |h| 
      c = h.hex.chr
      d = c.to_s.unpack("C*")[0].to_i
      if ((d < 32) || (d > 127))
        out += h
      else
        out += h.hex.chr
      end
    }
    return out
  end
  
  def Encoder.decode_char(str)
    out = ""
    str.split(/ /).each { |c|
      out = out + c.to_i.chr.to_s
    }
    return out
  end
  
  def Encoder.decode_uudecode(str)
    return str.unpack('u*').to_s
  end
  
  def Encoder.decode_octal(str)
    out = ""
    str.scan(/.../).each { |o|
      out = out + o.oct.chr
    }
    return out
  end
  
  def Encoder.decode_rot13(str)
    return str.downcase.rot13
  end
  
end

## Add methods to tab completion
enclist = Encoder.get_encode_list()
declist = Encoder.get_decode_list()
list = enclist.concat(declist)
list.uniq!
list.each { |l|
  $tabstrings.push(l.to_s)
}
