# vim: set ts=2 sw=2 tw=80
##############################
## Start of helping methods ##
##############################

## Return the description of the <name> module
def get_description(name)
  if File.exist?("#{$moduledir}/#{name}/description")
    desc = `cat #{$moduledir}/#{name}/description`
  else
    desc = "No description"
  end
  return desc.chomp
end

## Return the default values for the <name> module
def get_defaults(name)
  defs = []
  if File.exist?("#{$moduledir}/#{name}/defaults")
    begin
      file = File.open("#{$moduledir}/#{name}/defaults", "r")
      file.each_line {
        |line|
        defs.push(line.chomp)
      }
      file.close
    rescue
      STDERR.puts "\nUnable to read file #{$moduledir}/#{name}/defaults: #{$!}"
    end
  end
  return defs
end

## Return the commands for the <name> module
def get_commands(name)
  cmds = []
  if File.exist?("#{$moduledir}/#{name}/#{name.gsub(/\.module$/,"")}")
    begin
      file = File.open("#{$moduledir}/#{name}/#{name.gsub(/\.module$/,"")}", "r")
      file.each_line {
        |line|
        cmds.push(line.chomp)
      }
      file.close
    rescue
      STDERR.puts "\nUnable to read file #{$moduledir}/#{name}/#{name.gsub(/\.module$/,"")}: #{$!}\n"
    end
  end
  return cmds
end

## Return the module given by <mod_name>
def get_mod_by_name(mod_name)
  $modules.each { |mod|
    if mod.get_name == mod_name
      return mod
    end
  }
  return nil
end

## Return all the modules in a category
def get_module_names_from_category(cat_name)
  mod_names = []
  if File.exist?("#{$moduledir}/categories/#{cat_name}")
    begin
      file = File.open("#{$moduledir}/categories/#{cat_name}", "r")
      file.each_line {
        |line|
        mod_names.push(line.chomp)
      }
      file.close
    rescue
      STDERR.puts "\nUnable to read file #{$moduledir}/categories/#{cat_name}: #{$!}"
    end
  else
    puts "Category '#{cat_name}' does not exist."
  end
  return mod_names
end

## Print the lobster banner :D
def print_banner
  ## New header :D
  puts "=-" * 30
  puts "                         ,.---."   
  puts "               ,,,,     /    _ `."
  puts "                \\\\\\\\   /      \\  )"
  puts "                 |||| /\\/``-.__\\/          NSM"
  puts "                 ::::/\\/_"
  puts " {{`-.__.-'(`(^^(^^^(^ 9 `.========='"
  puts "{{{{{{ { ( ( (  (   (-----:="
  puts " {{.-'~~'-.(,(,,(,,,(__6_.'=========."
  puts "                 ::::\\/\\ "
  puts "                 |||| \\/\\  ,-'/\\           console"
  puts "                ////   \\ `` _/  )"
  puts "               ''''     \\  `   /"
  puts "                         `---''"
  puts "=-" * 30
  print "\n"
end

## Print welcome message
def print_welcome_message
  puts "=-" * 35
  puts "Welcome to #{$GREEN}NSM Console #{$NSM_VERSION}#{$RESET}, type '#{$WHITE}help#{$RESET}' to see available commands"
  puts "=-" * 35
  puts "Note: All modules are DISABLED by default, use '#{$WHITE}list#{$RESET}' to list available"
  puts "modules and '#{$WHITE}toggle <module>#{$RESET}' to disable/enable a module.\n\n"
end

## Load the modules in <dir>
def load_modules(dir)
  if $modules.length > 0
    $modules.each { |mod|
      $tabstrings.delete(mod.get_name())
    }
  end
  $modules = []

  if !File.directory?(dir)
    puts "Error: Module directory '#{dir}' is not a directory or does not exist."
    puts "No modules will be loaded."
    return
  end
  
  puts $color ? "Loading #{$CYAN}modules#{$RESET} from: #{dir}" : "Loading modules from: #{dir}"
  
  mod_num = 0
  mods = Dir.new(dir)
  ## Load modules
  mods.each { |mod_name|
    if mod_name =~ /\w\.module$/i
      print $color ? "Loading #{$CYAN}#{mod_name}#{$RESET}..." : "Loading #{mod_name}..."
      m = NSM_Module.new(mod_name.gsub(/\.module$/,""),
                         get_description(mod_name),
                         get_defaults(mod_name),
                         get_commands(mod_name))
      $modules.push(m)
      $tabstrings.push(m.get_name())
      puts "done."
      mod_num += 1
    end
  }
  puts $color ? "\n#{mod_num} #{$CYAN}modules#{$RESET} loaded.\n\n" : "\n#{mod_num} modules loaded.\n\n"
end

## Load the categories in the <dir>
def load_categories(dir)
  if $categories.length > 0
    $categories.each { |cat|
      $tabstrings.delete(cat.get_name())
    }
  end
  $categories = []
  
  dir = dir + "/categories"
  
  if !File.directory?(dir)
    puts "Error: Category directory '#{dir}' is not a directory or does not exist."
    puts "No categories will be loaded."
    return
  end
  
  puts "Loading categories from #{dir}"
  
  cat_num = 0
  cats = Dir.new(dir)
  ## Load categories
  cats.each { |cat_name|
    if cat_name !~ /\./
      if File.directory?(cat_name)
        puts $color ? "#{$RED}#{cat_name} is a directory, skipping...#{$RESET}" : "#{cat_name} is a directory, skipping..."
        next
      end
      print $color ? "Loading #{$BROWN}#{cat_name}#{$RESET}..." : "Loading #{cat_name}..."
      c = NSM_Category.new(cat_name,get_module_names_from_category(cat_name))
      ## Add to tab completion
      $categories.push(c)
      $tabstrings.push(c.get_name())
      puts "done."
      cat_num += 1
    end
  }
  puts $color ? "\n#{cat_num} #{$BROWN}categories#{$RESET} loaded.\n\n" : "\n#{cat_num} categories loaded.\n\n"
end

## Read from a directory reqursively
## 'dir' is the directory name
## 'rec' is a boolean, whether to recurse or not
def get_filelist(dir,rec)
  filelist = []
  d = Dir.new(dir)
  d.each { |name|
    ## Ignore '.', '..' and 'CVS'
    if name !~ /^\./ and name != "CVS"
      if File.file?(dir + "/" + name)
        filelist << dir + "/" +name
      elsif File.directory?(dir + "/" + name)
        if rec
          filelist.concat(get_filelist(dir + "/" + name,rec))
        else
          puts "Skipping directory " + name
        end
      else
        puts "Skipping " + dir + "/" + name
      end
    end
  }
  return filelist
end

## Read the ~/.nsmcrc file
def read_dotnsmcrc(file)
  begin
    fh = File.open(file,"r")
  rescue
    STDERR.puts "Unable to open file: #{file}, error: #{$!}"
    return
  end
  linenum = 1
  fh.each_line { |cmd|
    if cmd.length > 1 and cmd !~ /^#/
      #puts "line #{linenum}: #{cmd.chomp}"
      cmd.gsub!(/(\w)\s([\s\S]*)/) { $1 }
      cmd.chomp!
      args = $2
      args.strip! unless args.nil?
      
      
      begin
        Logger.write("[nsmcrc] #{cmd} #{args}\n")
        History.write("#{cmd} #{args}")
        CommandManager.execute(cmd,args) unless cmd.length < 1
      rescue LocalJumpError
        ## Ignore LocalJumpErrors, it just means we returned
      rescue NoMethodError
        STDERR.puts "Command '#{cmd}' unrecognized. Check line #{linenum} of #{file}"
      rescue
        STDERR.puts "File: #{file}"
        STDERR.puts "Line: #{linenum}"
        STDERR.puts "Command: #{cmd}"
        STDERR.puts "Args: #{args}"
        STDERR.puts "Error encountered: #{$!}"
      end
    end
    linenum += 1
  }
end

## Toggle a module
def toggle_module(name)
  return if name.nil?
  
  if name == "all"
    $modules.each { |mod| mod.set_enabled(true); }
    $categories.each { |cat| cat.set_enabled_mods(true); }
    puts "All modules and categories turned on."
    return
  elsif name == "none"
    $modules.each { |mod| mod.set_enabled(false); }
    $categories.each { |cat| cat.set_enabled_mods(false); }
    puts "All modules and categories turned off."
    return
  else
    $categories.each { |cat|
      if cat.get_name() == name
        if cat.enabled?
          cat.set_enabled_mods(false)
          puts "#{name} category turned off."
        else
          cat.set_enabled_mods(true)
          puts "#{name} category turned on."
        end
        return
      end
    }
    
    $modules.each { |mod|
      if mod.get_name() == name
        if mod.enabled?
          mod.set_enabled(false)
          puts "#{name} module turned off."
        else
          mod.set_enabled(true)
          puts "#{name} module turned on."
        end
        return
      end
    }
  end
  puts "Module '#{name}' not found."
end

## Return the filename of the uncompressed temporary file
# This function is actually deprecated because the "file"
# command automatically unzips before it runs any of the
# modules get run
def get_uncompressed_filename(file)
  if file =~ /\.gz$/i
    begin
      puts "Attempting decompression..."
      require 'tempfile'
      require 'zlib'
      puts "Original:  #{file}"
      tmpname = `basename #{file}`.chomp.gsub!(/\.gz/,"")
      f = Tempfile.new(tmpname,Dir.pwd)
      File.open(file) do |file|
        gz = Zlib::GzipReader.new(file)
        f.write(gz.read)
        gz.close
      end
      file = f.path
      puts "Temporary: #{file}"
      f.close
    rescue
      STDERR.puts "Error decompressing: #{$!}"
    end
  end
  return file
end

# From a pcap file, generate a list of IP addresses
def gen_list_from_pcap
  list = {}

  # initialize empty array of file names
  fnames = []

  # get a list of files, otherwise just do one
  if (File.directory?($datafile))
    fnames = get_filelist($datafile,true)
  else
    fnames << $datafile
  end

  fnames.each { |file|
    begin
      pp = PcapParser.new(File.open(file))

      pp.each { |pkt|
        next unless pkt.ip?

        # I'm still not sure whether I should do source *AND* dest ips
        if list.has_key?(pkt.ip_src.to_i)
          list[pkt.ip_src.to_i] = list[pkt.ip_src] + 1
        else
          list[pkt.ip_src.to_i] = 1
        end

        # ...so I'll do both
        if list.has_key?(pkt.ip_dst.to_i)
          list[pkt.ip_dst.to_i] = list[pkt.ip_dst] + 1
        else
          list[pkt.ip_dst.to_i] = 1
        end
      }
    rescue
      STDERR.puts "Error generating list of IP addresses: #{$!}"
    end
  }

  return list
end
