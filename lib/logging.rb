# vim: set ts=2 sw=2 tw=80
# NSM-Console logging to a text file
class Logger
  @@logfile = nil
  
  def initialize(name)
    @@logfile = name.to_s
  end
  
  def Logger.write(line)
    if @@logfile.nil?
      puts "Error. No logfile specified."
      return
    end
    
    if !File.exist?(@@logfile)
      begin
        system("touch #{@@logfile}")
      rescue
        STDERR.puts "Error creating logfile #{@@logfile}: #{$!}"
        exit
      end
    end
    
    begin
      File.open(@@logfile, "a") do |f|
        f.write(line)
      end
    rescue
      STDERR.puts "Error writing to logfile: #{$!}"
    end
    
  end

  # Accessor for log filename
  def Logger.get_log_filename
    @@logfile
  end

  # Initialize logging given a filename
  def Logger.start_logging(logfilename)
    puts "Logging to #{logfilename}\n\n"
    Logger.new(logfilename)
    ## Write initial entry
    Logger.write("-" * 80)
    Logger.write("\n")
    Logger.write("Log for nsm-console begun at #{Time.now.year}\
                 -#{Time.now.month}-#{Time.now.day} #{Time.now.hour}\
                 :#{Time.now.min}:#{Time.now.sec}\n")
    Logger.write("-" * 80)
    Logger.write("\n")
  end

  def Logger.get_def_log_file
    # This will default to the <nsm-root-dir>/logs/nsm-log.<time>
    logfilename = File.dirname(__FILE__) + "/../logs/nsm-log."
    logfilename.concat(Time.now.year.to_s)
    logfilename.concat(Time.now.month.to_s)
    logfilename.concat(Time.now.day.to_s)
    logfilename.concat(".log")
    return logfilename
  end
  
end
