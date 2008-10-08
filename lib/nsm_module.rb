# vim: set ts=2 sw=2 tw=80
## NSM_Module is the class encapsulating each module
class NSM_Module
  
  def initialize(name,desc,defs,cmds)
    # mod_name - String
    @mod_name = name
    # enabled - boolean
    @enabled = false
    # description - String
    @description = desc
    # defaults - Hash
    @defaults = parse_defaults(defs)
    # commands - Array
    @commands = cmds
  end
  
  def enabled?
    @enabled == true
  end
  
  def get_name
    return @mod_name
  end
  
  def get_defaults
    return @defaults
  end
  
  def get_commands
    return @commands
  end
  
  def set_enabled(en)
    @enabled = en
  end
  
  ## dump prints the name and description of the module
  def dump
    if self.enabled?
      print $color ? "#{$GREEN}[+]#{$RESET} " : "[+] "
    else
      print $color ? "#{$RED}[-]#{$RESET} " : "[-] "
    end
    puts $color ? "#{$CYAN}#{@mod_name}#{$RESET} - #{@description}" : "#{@mod_name} - #{@description}"
  end

  ## cat the 'info' file for the module
  def print_info
    mname = self.get_name
    filename = "#{$moduledir}/#{mname}.module/info"
    if File.exist?(filename)
      system("cat #{filename}")
    else
      puts "No info file found."
    end
  end

  ## update_option, given the name of the options and the value,
  ## set the option to be the new value
  def update_option(name,val)
    if name.length < 1 or val.length < 1
      puts "Invalid option or value"
      return
    end
    
    defs = self.get_defaults
    if defs[name].nil?
      puts "The variable #{name} is not settable."
      return
    end
    puts "Setting ${#{name.upcase}} = #{val}"
    defs[name] = val
  end

  ## Run commands executes the module against the given filename
  def run_commands(filename)
    ## We have to recalculate the basename, because it could be a directory
    basename = `basename #{filename}`.chomp
    @commands.each { |cmd|
      mod_name = self.get_name
      
      ## Substitutions for output dir
      outdir = String.new($outputdir)
      outdir.gsub!(/\$\{PCAP_BASE\}/i,basename)
      outdir.gsub!(/\$\{MODULE_DIR\}/i,$moduledir)
      outdir.gsub!(/\$\{MODULE_NAME\}/i,mod_name)
      
      dirname = outdir + "/" + self.get_name
      
      ## Don't replace the original command, otherwise can't change filename
      ## Do the most important 3 first
      new_cmd = cmd.gsub(/\$\{PCAP_FILE\}/i,filename)
      new_cmd.gsub!(/\$\{PCAP_BASE\}/i,basename)
      new_cmd.gsub!(/\$\{MODULE_DIR\}/i,$moduledir)
      new_cmd.gsub!(/\$\{MODULE_NAME\}/i,mod_name)
      new_cmd.gsub!(/\$\{OUTPUT_DIR\}/i,dirname)
      
      ## Replace others with options
      defs = self.get_defaults
      defs.each_pair { |d, val|
        ## This allows the use of these 3 vars in the defaults file
        new_val = String.new(val)
        new_val.gsub!(/\$\{PCAP_FILE\}/i,filename)
        new_val.gsub!(/\$\{PCAP_BASE\}/i,basename)
        new_val.gsub!(/\$\{MODULE_DIR\}/i,$moduledir)
        new_val.gsub!(/\$\{MODULE_NAME\}/i,mod_name)
        new_val.gsub!(/\$\{OUTPUT_DIR\}/i,dirname)
        
        new_cmd.gsub!(/\$\{#{d}\}/i,new_val)
      }
      
      ## Build the output directories if they don't exist
      if File.exist?(dirname)
        if File.directory?(dirname)
          puts "Directory #{dirname} already exists, not recreating"
        else
          puts "Error: #{dirname} exists, but is not a directory."
          return
        end
      else
        puts "Creating directory #{dirname}"
        begin
          res = system("mkdir -p #{dirname}")
          Logger.write("[exit: #{$?}] mkdir -p #{dirname}\n")
        rescue
          STDERR.puts "Error executing: #{$!}"
          STDERR.puts "system() returned: #{res}"
        end
      end
      
      ## Actually execute the command, logging the command and exit status
      puts "--> #{new_cmd.to_s}"
      begin
        res = system("#{new_cmd.to_s}")
        Logger.write("[exit: #{$?}] #{new_cmd.to_s}\n")
      rescue
        STDERR.puts "Error executing: #{$!}"
        STDERR.puts "system() returned: #{res}"
      end
    }
  end

  private
  ## Parse through each default (as a string)
  def parse_defaults(defs)
    new_defs = {}
    defs.each { |d|
      a = d.split(/=/,2)
      new_defs.store(a[0],a[1])
    }
    return new_defs
  end

end

