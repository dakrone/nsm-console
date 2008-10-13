# vim: set ts=2 sw=2 tw=80
##################################################################
##
## This file is for declaring the NSM pseudo-shell commands
## Please put them in block syntax like the following:
##
## command "<description>", "<command>", do |<argument_name>|
## <command execution>
## end
##
## The <description> is used when the 'help' command is called.
## <argument_name> is an array passed in by the commands args.
##
##################################################################

## Help command
command "Display commands and command usage. 'help <cmd>' for more detail",
"help" do |args|
  args = args[0].to_s
  
  if args.length < 1
    puts "\nUse 'help <cmd>' to get more detail about a command"
    puts "\nAvailable Commands:"
    puts "-" * 70
    CommandManager.get_commands.sort.each { |k, val|
      print " #{val.exec}"
    }
    print "\n\n"
    return
  end
  puts " Commands matching '#{args}':"
  puts "-" * 70
  CommandManager.get_commands.each { |k, val|
    if val.exec =~ /#{args}/i or args == "all"
      print " #{val.exec}"
      print " " * (15 - val.exec.length)
      print "- #{val.desc}\n"
    end
  }
  print "\n"
  
end

## Quit/q command
command "Quit the program.", "quit" do |args|
  puts "Goodbye!"
  exit
end
command "Quit the program.", "q" do |args|
  puts "Goodbye!"
  exit
end
  
## List command
command "List all modules and their enabled or disabled states", "list" do |args|
  args = args[0].to_s

  puts "\nCategories:"
  $categories.each { |cat|
    if (args =~ /en/)
      cat.dump if cat.enabled?
    elsif (args =~ /dis/)
      cat.dump unless cat.enabled?
    else
      cat.dump
    end
  }
  puts "--------------------------"
  puts "\nModules:"
  $modules.each { |mod|
    if (args =~ /en/)
      mod.dump if mod.enabled?
    elsif (args =~ /dis/)
      mod.dump unless mod.enabled?
    else
      mod.dump
    end
  }
  puts "--------------------------"
  puts $color ? "#{$GREEN}+ = Enabled#{$RESET}\n#{$RED}- = Disabled#{$RESET}" : "+ = Enabled\n- = Disabled"
end

## Toggle command
command "Toggle a module on or off\n\t\tUsage: toggle <module name>\n\t\tYou can also use \
'toggle all' and 'toggle none' to enable/disable all modules",
"toggle" do |name|
  name = name[0].to_s
  
  if name.length < 1
    puts "Need a module or category name"
    return
  end
  
  # Split by space, toggling each module
  mods = name.split(" ")

  mods.each { |name|
    toggle_module(name)
  }
  return
end

## Options command
command "Display global options. If <module> is given, display that module's \n\t\t\
options as well (ex: 'options hash'). 'options' will also display the commands \n\t\t\
that will be run (before substitution) for that module.",
"options" do |name|
  puts "\nGlobal options:"
  puts "-" * 35
  if File.directory?($datafile)
    puts "PCAP DIRECTORY: #{$datafile}"
    puts "Pcap basename will be determined individually"
  else
    puts $color ? "${#{$MAGENTA}PCAP_FILE#{$RESET}}: #{$datafile}" : "${PCAP_FILE}: #{$datafile}"
    puts $color ? "${#{$MAGENTA}PCAP_BASE#{$RESET}}: #{$basefile}" : "${PCAP_BASE}: #{$basefile}"
  end
  puts $color ? "${#{$MAGENTA}OUTPUT_DIR#{$RESET}}: #{$outputdir}" : "${OUTPUT_DIR}: #{$outputdir}"
  puts $color ? "${#{$MAGENTA}MODULE_DIR#{$RESET}}: #{$moduledir}" : "${MODULE_DIR}: #{$moduledir}"
  print "\n"
  
  name = name[0].to_s

  return if name.length < 1

  mod = get_mod_by_name(name)
  if mod.nil?
    puts "Unknown module #{name}"
    return
  end
  # Get the default values for a module
  defs = mod.get_defaults
  puts "Options for module #{name}:"
  puts "-" * 35
  defs.each_pair { |d, val|
    puts $color ? "${#{$GREEN}#{d}#{$RESET}} = #{val}" : "${#{d}} = #{val}"
  }
  # Get the command-list to show what will be run
  cmds = mod.get_commands
  puts "\nCommand(s) to be executed for module #{name}:"
  puts "-" * 35
  cmds.each { |c| puts c }
  print "\n"
end

## File command
command "Set the ${PCAP_FILE} filename (the file to be analyzed).", "file" do |name|
  name = name[0][0]

  puts "name: #{name}"

  if name.length < 1
    puts "Need a pcap filename"
    return
  end
  $datafile = name
  #$datafile.gsub!(/~/,"#{ENV['HOME']}")
  if $datafile =~ /\.gz$/i
    begin
      puts "Attempting decompression..."
      # Attempt to do zlib decompression on the pcap file
      require 'tempfile'
      require 'zlib'
      # Get handle for a new ungzip'd file, we want the full path
      nfname = Dir.pwd + "/" + `basename #{$datafile}`.chomp.delete(".gz")
      f = File.new(nfname,"w")
      File.open($datafile) do |file|
        gz = Zlib::GzipReader.new(file)
        # Write to a new file
        f.write(gz.read)
        gz.close
      end
      $datafile = f.path
      puts "New datafile: #{$datafile}"
      f.close
    rescue
      STDERR.puts "Error decompressing: #{$!}"
    end
  end

  # Fully expand the path of the datafile
  $datafile = File.expand_path(File.dirname($datafile)) + "/" + `basename #{$datafile}`.chomp
  puts "[!] WARNING: File doesn't exit!" if !File.exist?($datafile)
  if File.directory?($datafile)
    puts "PCAP DIRECTORY: #{$datafile}"
    puts "Pcap basename will be determined by individual files."
  else
    puts $color ? "Setting ${#{$MAGENTA}PCAP_FILE#{$RESET}} = #{$datafile}" : "Setting ${PCAP_FILE} = #{$datafile}"
  end
  $basefile = `basename #{$datafile}`.chomp
  puts $color ? "Setting ${#{$MAGENTA}PCAP_BASE#{$RESET}} = #{$basefile}" : "Setting ${PCAP_BASE} = #{$basefile}"
  print "\n"
end

## Output command
command "Set the ${OUTPUT_DIR} output directory.", "output" do |name|
  name = name[0].to_s
  
  if name.length < 1
    puts "Need a output directory name"
    return
  end
  # Replace '~' in the output path
  name.gsub!(/~/,"#{ENV['HOME']}")
  puts $color ? "Setting ${#{$MAGENTA}OUTPUT_DIR#{$RESET}} = #{name}" : "Setting ${OUTPUT_DIR} = #{name}"
  $outputdir = name
end

## Run command
command "Run enabled analysis files on the data (pcap) file. Use run <modname> to run a single module without toggling it.", "run" do |args|
  args = args.to_s
      
  if $datafile == ""
    puts "Error: no pcap datafile has been specified"
    puts "specify one with 'file <file.pcap>'"
    return
  end
  
  if !File.exist?($datafile)
    puts "ERROR: #{$datafile} does not exist. Please set file using 'file <filename>'."
    return
  end
  
  fnames = []
  if File.directory?($datafile)
    puts "#{$datafile} is a directory, processing sub-files..."
    fnames = get_filelist($datafile,true)
    puts fnames
  else
    fnames << $datafile
  end
  
  # If an argument is specified, just run that and return
  if (args.length > 1)
    mod = get_mod_by_name(args)
    if mod.nil?
      puts "No module by that name loaded."
      return
    end
    
    puts "===> module #{mod.get_name} running..."
    fnames.each { |file|
      mod.run_commands(get_uncompressed_filename(file))
    }
    return
  end

  puts "\nExecuting analysis...\n\n"
  
  $modules.each { |mod|
    if mod.enabled?
      puts "===> module #{mod.get_name} running..."
      fnames.each {
        |file|
        mod.run_commands(get_uncompressed_filename(file))
      }
      puts "===> module #{mod.get_name} finished."
    else
      puts "===> module #{mod.get_name} skipped."
    end
    print "\n"
  }
end

## Info command
command "Show detailed module information.", "info" do |name|
  name = name[0].to_s
  
  mod = get_mod_by_name(name)
  if mod.nil?
    puts "Module not found."
    return
  end
  mod.print_info
  print "\n"
end

## Set command
command "Usage: set <mod> <opt> <val>\n\t\tSet the <mod> module's option \n\t\t\
'<opt>' to have the value <val>. (ex: 'set aimsnarf OUTPUT_FILE ${PCAP_BASE}.aim.txt').",
"set" do |args|
  args = args[0].to_s

  if args.length < 1
    puts "Need a module name."
    return
  end
  arglist = args.split(/ /, 3)
  mod = get_mod_by_name(arglist[0])
  if mod.nil?
    puts "Module #{arglist[0]} not found."
    return
  end
  if arglist[1].nil?
    puts "Need variable name (ex: OUTPUT_DIR)"
    return
  end
  if arglist[2].nil?
    puts "Need variable value (ex: file.pcap)"
    return
  end
  mod.update_option(arglist[1],arglist[2])
end

## Modload command
command "Load the modules from the given directory. Note that this replaces \n\t\t\
the currently loaded modules.",
"modload" do |dir|
  dir = dir[0].to_s
  
  if dir.length < 1
    puts "Please specify a module directory."
    return
  end
  
  # expand directory name (like ~)
  dir = File.expand_path(dir)

  if !File.directory?(dir)
    puts "#{dir} is not a directory."
    return
  end
  
  $moduledir = dir
  load_modules($moduledir)
  
  load_categories($moduledir)
  
end

## Exec command
command "Execute an external command", "exec" do |args|
  args = args[0].to_s
  
  if args.length < 1
    puts "Need a program to execute."
    return
  end
  
  cmd = args.gsub(/\$\{PCAP_FILE\}/i,$datafile)
  cmd.gsub!(/\$\{PCAP_BASE\}/i,$basefile)
  cmd.gsub!(/\$\{MODULE_DIR\}/i,$moduledir)
  cmd.gsub!(/\$\{OUTPUT_DIR\}/i,$outputdir)
  
  puts "Executing: #{cmd}"
  
  system(cmd)
  Logger.write("[exit: #{$?}] #{cmd.to_s}\n")
  puts "Exit status: #{$?}"
end
command "Execute an external command","e" do |args|
  CommandManager.execute("exec",args)
end

## Logfile command
command "Set the file to log commands to", "logfile" do |file|
  file = file[0].to_s
  
  if file.length < 1
    puts "Need a new logfile name."
    print "\n"
    puts "Currently logging to:"
    puts Logger.get_log_filename
    return
  end
  
  if File.directory?(file)
    puts "#{file} is a directory, can't log to that file."
    return
  end
  
  puts "New logfile is: #{file}"
  Logger.new(file)
  
  Logger.write("-" * 80)
  Logger.write("\n")
  Logger.write("Log for nsm-console begun at #{Time.now.year}-#{Time.now.month}-#{Time.now.day} #{Time.now.hour}:#{Time.now.min}:#{Time.now.sec}\n")
  Logger.write("-" * 80)
  Logger.write("\n")
  
end

## History command
command "Display command history", "history" do |args|
  History.print()
end

## Encode command
command "Encode value or file into different form\n\t\tRun without any options to see \
usage",
"encode" do |args|
  args = args[0].to_s

  if args.length < 2
    puts "\nUsage:\n\n"
    puts "encode [-f] <type> [file|string]"
    puts "Use -f to specify a file"
    puts "\nAvailable encoding:"
    puts "-" * 30
    Encoder.get_encode_list.each { |e| puts e; }
    return
  end

  if (args =~ /-f/)
    arglist = args.split(/ /, 3)
    type = arglist[1].to_s
    str = File.open("#{arglist[2]}").readlines
  else
    arglist = args.split(/ /, 2)
    type = arglist[0].to_s
    str = arglist[1].to_s.chomp
  end
  
  output = ""
  
  print "\n"
  puts "Encoding ascii --> #{type}..."
  puts "Output ([]'s added to show beginning and end):\n\n"
  
  begin
    cmd = "Encoder.encode_#{type}(\"#{str}\")"
    output = output + eval(cmd)
  rescue NoMethodError
    puts "Encoding not found."
  rescue
    STDERR.puts "Error: #{$!}"
    return
  end
  
  print "["
  print output
  print "]\n\n"
  
end

## Decode command
command "Decode value or file into different ascii\n\t\tRun without any options to see \
usage",
"decode" do |args|
    
  args = args[0].to_s

  if args.length < 1
    puts "\nUsage:\n\n"
    puts "decode [-f] <type> [file|string]"
    puts "Use -f to specify a file"
    puts "\nAvailable decoding:"
    puts "-" * 30
    Encoder.get_decode_list.each { |d| puts d; }
    return
  end

  if (args =~ /-f/)
    arglist = args.split(/ /, 3)
    type = arglist[1].to_s
    str = File.open("#{arglist[2]}").readlines
    # Get rid of line-breaks
    str.collect! { |n| n.gsub!(/\n/,"") }
  else
    arglist = args.split(/ /, 2)
    type = arglist[0].to_s
    str = arglist[1].to_s.chomp
  end

  output = ""
  
  print "\n"
  puts "Decoding #{type} --> ascii..."
  puts "Output ([]'s added to show beginning and end):\n\n"

  begin
    cmd = "Encoder.decode_#{type}(\"#{str}\")"
    output = eval(cmd)
  rescue NoMethodError
    puts "Decoding not found."
    STDERR.puts "Error: #{$!}"
  rescue
    STDERR.puts "Error: #{$!}"
    return
  end
  
  print "["
  print output
  print "]\n\n"
  
end

## Eval command
command "Evaluate a single line in Ruby","eval" do |args|
  args = args[0].to_s
  if args.length < 1
    puts "Need a line to eval."
    return
  end
  
  print "=> "
  begin
    ret = eval("#{args}")
  rescue
    STDERR.puts "Caught error: #{$!}"
  end
  puts "#{ret}"
end

## Credits command :D
command "Display program credits","credits" do |args|
  print "\n"
  
  puts "Original design and development:"
  puts "-" * 40
  puts "Matthew Lee Hinman - matthew [dot] hinman [at] gmail [dot] com"
  puts "Scholar - PcapParser library, flowtag module (thanks scholar!)"
  puts "JohnQPublic - Clamscan module"
  puts "Chmeee - afterglow module"
  
  print "\n"
  puts "Ideas:"
  puts "-" * 40
  puts "Geek00l, Enhanced, Scholar"

  print "\n"
end

## Print command
command "Display a packet's information and payload.\n\t\tUse with no arguments to see usage.",
"print" do |args|
  args = args[0].to_s
  
  if args.length < 1
    puts "Usage:"
    puts "\nprint <option> #|#-#|*"
    puts "Options:"
    puts "-f  Display entire packet, not just payload"
    puts "-x  Display packet payload in hex and ascii, similar to -X option for tcpdump"
    puts "-a  Display packet payload as ascii"
    puts "-h  Display packet payload in hex"
    puts "No option will print only connection information"
    puts "\nExamples:"
    puts "'p 1-10' print out connection information for packets 1 through 10"
    puts "'p -x 101' print packet 101's payload in tcpdump -X format"
    puts "'p -a 1000-*' print packet 1000 through the end in ascii format"
    puts "'p *' print all the connection streams"
    print "\n"
    return
  end
  
  if !File.exist?($datafile)
    puts "File #{$datafile} does not exist or no file specified."
    return
  end
  
  #puts "Args: #{args}"
  opts = "list"

  full = false
  if args =~ /-f/i
    full = true
    puts "Printing full packet"
    args.gsub!(/\s*-f\s*/i,"")
  end

  if args =~ /-x/i
    opts = "full"
    args.gsub!(/\s*-x\s*/i,"")
  elsif args =~ /-a/i
    opts = "ascii"
    args.gsub!(/\s*-a\s*/i,"")
  elsif args =~ /-h/i
    opts = "hex"
    args.gsub!(/\s*-h\s*/i,"")
  end
  
  if args =~ /,/i
    ranges = args.split(/,/)
    sranges = ranges[0,ranges.length-1]
    opt = ""
    opt = "-x " if opts == "full"
    opt = "-a " if opts == "ascii"
    opt = "-h " if opts == "hex"
    newrange = sranges.join(",")
    newrange = opt + newrange
    CommandManager.execute("print",newrange)
    print "\n"
    args = ranges[ranges.length-1]
  end
  
  min = max = 1
  if args =~ /(\d+)\s*-\s*(\d+)/
    min = $1.to_i
    max = $2.to_i
  elsif args =~ /(\d+)\s*-\s*\*/
    min = $1.to_i
    max = "*"
  elsif args == "*"
    max = "*"
  else
    min = args.to_i
    max = min
  end
  
  if File.directory?($datafile)
    fnames = get_filelist($datafile,true)
    fnames.each { |file|
      file = get_uncompressed_filename(file)
      puts "\nFile: #{file}\n\n"
      print_pkt_range(file,min,max,opts,full)
    }
  else
    print_pkt_range(get_uncompressed_filename($datafile),min,max,opts,full)
  end
end
command "An alias for the 'print' command.", "p" do |args|
  CommandManager.execute("print",args)
end

## Color command
command "Toggle the terminal color output on or off","color" do |args|
  args = args[0].to_s
  if args =~ /off/i
    puts "Color is now off."
    $color = false
  elsif args =~ /on/i
    puts "#{$CYAN}C#{$RED}o#{$GREEN}l#{$BROWN}o#{$MAGENTA}r#{$RESET} is now #{$BLUE}on!#{$RESET}"
    $color = true
  elsif $color
    puts "Color is now off."
    $color = false
  else
    puts "#{$CYAN}C#{$RED}o#{$GREEN}l#{$BROWN}o#{$MAGENTA}r#{$RESET} is now #{$BLUE}on!#{$RESET}"
    $color = true
  end
end

## Alias command
command "Create an alias for a command, Usage: alias <cmd> = <newcmd(s)>",
"alias" do |args|
  args = args.to_s
  if args.length < 1
    puts "Current aliases:"
    puts "-" * 30
    ## Print aliases
    a = NSM_Alias.get_aliases()
    a.each { |k,v|
      puts "#{k}\t\t- #{v}"
    }
    print "\n"
    return
  end
  
  args = args.chomp.split("=",2)
  if (args.length < 2) or args[1].length < 1
    puts "Usage: alias <cmd>='<newcmd>'"
    return
  end
  
  ## Strip our whitespace so you can space out the commands
  args[0] = args[0].strip
  args[1] = args[1].strip
  
  ## Strip out any surrounding '', if they're used to GNU alias
  puts "Aliasing '#{args[0]}' to #{args[1]}"
  args[1] =~ /\'(.*)\'/
  cmd = $1.nil? ? args[1] : $1
  NSM_Alias.set_alias(args[0],cmd)
  
end

## Unalias command
command "Unalias a command, Usage: 'unalias <name>'","unalias" do |name|
  name = name.to_s
  
  if name.length < 1
    puts "Please specify an alias to unalias"
  end
  
  result = NSM_Alias.del_alias(name)
  unless result.nil?
    puts "'#{name}' successfully unaliased"
  else
    puts "There is no #{name} alias."
  end
end

## CheckIP command
command "Check an IP address against the Harimau watchlist","checkip" do |addr|
  addr = addr.to_s
  
  if addr.length < 1
    puts "Need an IP address to query"
    return
  end
  
  truncaddr = String.new(addr)
  truncaddr =~ /(\d{1,3}\.\d{1,3}\.\d{1,3})\./
  truncaddr = String.new($1)
  if system("which wget 2>&1 > /dev/null")
    out = `wget -q -O - http://watchlist.security.org.my/watchlist/show?ip=#{addr} | grep '#{truncaddr}'`
    if out.length < 1
      puts "#{addr}: No records"
    else
      puts out.chomp
    end
  else
    require 'net/http'
    
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

## Dump command
command "Dump the specified packet contents to a file, run without arguments for usage",
"dump" do |args|
  args = args[0].to_s
  
  if args.length < 2
    puts "Usage:"
    puts "\ndump [-f] #|#-#|* <filename>"
    puts "\nExamples:"
    puts "'dump 1-10 a.out' - Dump the payloads of packets 1-10 into a.out"
    puts "'dump 1,5,7-9 a.out' - Dump the payloads of packets 1,5,7,8,9 into a.out"
    puts "'dump 1000-* a.out' - Dump packets 1000 through the end into a.out"
    puts "'dump * a.out' - Dump all the packet payloads into a.out"
    print "\n"
    puts "The '-f' flag dumps the ENTIRE packet, not just the payload"
    print "\n"
    return
  end
  
  if !File.exist?($datafile)
    puts "File #{$datafile} does not exist or no file specified."
    return
  end

  fulldump = false
  if args =~ /^-f /
    args = args[3,args.length]
    puts "New args: #{args}"
    puts "Dumping full packet, not just payload..."
    fulldump = true
  end
  
  outputfile = String.new(args.strip)
  ## hack hack hack, but I wanted to do it in one line
  outputfile = outputfile.reverse.split(/ /,2)[0].reverse
  args.gsub!(/#{outputfile}/,"")
  
  if args =~ /,/i
    ranges = args.split(/,/)
    sranges = ranges[0,ranges.length-1]
    newrange = sranges.join(",")
    newrange = newrange + " " + outputfile
    CommandManager.execute("dump",newrange)
    args = ranges[ranges.length-1]
  end
  
  min = max = 1
  if args =~ /(\d+)\s*-\s*(\d+)/
    min = $1.to_i
    max = $2.to_i
  elsif args =~ /(\d+)\s*-\s*\*/
    min = $1.to_i
    max = "*"
  elsif args =~ /\*/
    min = 1
    max = "*"
  else
    min = args.to_i
    max = min
  end
  
  # Interate through the files in the directory if we were given a directory
  # instead of a single file.
  if File.directory?($datafile)
    fnames = get_filelist($datafile,true)
    fnames.each { |file|
      file = get_uncompressed_filename(file)
      puts "\nFile: #{file}\n\n"
      rawwrite_pkt_range(file,min,max,outputfile,fulldump)
    }
  else
    ## Uncompressing doesn't work yet, hopefully soon
    rawwrite_pkt_range(get_uncompressed_filename($datafile),min,max,outputfile,fulldump)
  end
  
end


## The ip2asn command
command "Find the ASN for a given IP address","ip2asn" do |addr|

  addr = addr.to_s.chomp

  if addr.length < 1
    puts "Need an IP address to query"
    return
  end

  begin
    require 'socket'
    # Use the cymru team's ip->asn server
    s = TCPSocket.new('whois.cymru.com',43)
    s.write("begin\n")
    s.write(addr)
    s.write("\n")
    s.write("end\n")

    while line = s.gets
      print line
    end
    s.close
    print "\n"
  rescue
    puts "Encountered error: #{$!}"
  end

end


## The iplist command
command "Generate a list of all the IPs in a file. Usage: iplist [file] (if no file is specified, stdout is used)","iplist" do |file|
  file = file.to_s.chomp

  iplist = {}
  
  # Helper method to generate hash list key=ip, value=number
  iplist = gen_list_from_pcap()  

  # Sort the list backwards by packet count
  iplist = iplist.sort {|a,b| b[1]<=>a[1]}

  if file.length > 1
    puts "Dumping iplist to #{file}..."
    begin
      # Append to file
      fd = File.open(file, "a")
      fd.puts "=== IP list for #{$basefile} ==="
      iplist.each { |ip, pnum|
        addr = [ip].pack("N").unpack("C4").join(".")
        fd.print addr
        fd.print "\t"
        fd.puts pnum
      }
    rescue
      STDERR.puts "Error writing to file: #{$!}"
    end
  else
    if File.directory?($datafile)
      print "=== IP list for "
      fnames = get_filelist($datafile,true)
      fnames.each { |f| print f; print " " }
      puts "==="
    else
      puts "=== IP list for #{$basefile} ==="
    end
    iplist.each { |ip, pnum|
      addr = [ip].pack("N").unpack("C4").join(".")
      print addr
      print "\t"
      puts pnum
    }
  end

end


## The update command
command "Update NSM-Console to the latest version from SVN, use -v for verbose", "update" do |args|
  puts "Updating NSM-Console from svn..."
  args = args.to_s.chomp
  verbose = args =~ /-v/ ? true : false
  
  unless system("which svn 2>&1 > /dev/null")
    STDERR.puts "svn not found, please install subversion and try again."
  end

#  puts "Generating update files..." if verbose
#  `mkdir -p /tmp/nsmc-update` unless File.directory?("/tmp/nsmc-update")
#    
#  svnconf = File.open("/tmp/nsmc-update/config","w")
#  svnconf.puts "[auth]"
#  svnconf.puts "[helpers]"
#  svnconf.puts "[tunnels]"
#  svnconf.puts "ssh = ssh -p 1337"
#  svnconf.puts "[miscellany]"
#  svnconf.puts "[auto-props]"
#  svnconf.close

  puts "Fetching newest revision from svn..." if verbose

  puts "svn co --non-interactive http://svn.security.org.my/trunk/rawpacket-root/usr/home/analyzt/rp-NSM/nsm-console ." if verbose

  system("svn co --non-interactive http://svn.security.org.my/trunk/rawpacket-root/usr/home/analyzt/rp-NSM/nsm-console .")

  puts "Return status: #{$?}" if verbose

  if $? != 0
    STDERR.puts "\nThere was an error while updating, email lee [at] writequit [dot] org"
  else
    STDERR.puts "\nDone. Restart NSM-Console to use new version" 
  end

end

