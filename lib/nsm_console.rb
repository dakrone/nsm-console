# vim: set ts=2 sw=2 tw=80
class NSM_Console
  $PROMPT = "nsm> "
  $CPROMPT = "\033[32mnsm\033[0m> "

  # Save our default standard out
  $DEF_STDOUT = STDOUT.dup
  
  def initialize(args)

    # flag to redirect stdout for startup
    quiet_startup = false

    if (args.include?("-q"))
      # Remove -q from the arguments
      args.delete_at(0)
      quiet_startup = true
    end

    if quiet_startup
      # Save the current STDOUT so we can reopen it
      saved_stdout = STDOUT.dup
      # reopen /dev/null (or NUL) to quiet output
      STDOUT.reopen( RUBY_PLATFORM =~ /mswin/ ? "NUL" : "/dev/null" )
    end

    ## Print the lobster
    print_banner()
    puts "NSM Console version #{$NSM_VERSION}"
    print "\n"
      
    ## Set {$PCAP_FILE} if passed in as an argument
    CommandManager.execute("file",args[0]) if args.length > 0

    ## Load modules
    load_modules($moduledir)
    load_categories($moduledir)

    ## Initialize logging
    logfile = Logger.get_def_log_file
    Logger.start_logging(logfile)

    puts $color ? "Default ${#{$MAGENTA}OUTPUT_DIR#{$RESET}} is '#{$outputdir}'" : "Default ${OUTPUT_DIR} is '#{$outputdir}'"
    puts $color ? "Default ${#{$MAGENTA}MODULE_DIR#{$RESET}} is '#{$moduledir}'" : "Default ${MODULE_DIR} is '#{$moduledir}'"

    cmd = ""

    print "\n"
    
    ## Read ~/.nsmcrc
    rcfile = ENV['HOME']
    rcfile += "/.nsmcrc"
    if File.exist?(rcfile)
      print "Reading ~/.nsmcrc..."
      if !quiet_startup
        old_stdout = STDOUT.dup
        STDOUT.reopen( RUBY_PLATFORM =~ /mswin/ ? "NUL" : "/dev/null" )
      end
      read_dotnsmcrc(rcfile)
      if !quiet_startup
        STDOUT.reopen(old_stdout)
      end
      print "done.\n\n"
    end

    if quiet_startup
      # reopen stdout so we can write output
      STDOUT.reopen(saved_stdout)
    end
  end

  def run
    ## Print the welcome message
    print_welcome_message()

    ## Command loop until quit
    loop {

      ## New method uses readline so we can use tab-completion
      begin
        # I put this line in because after piping the prompt wouldn't show up
        if STDOUT != $DEF_STDOUT
          print "\n"
        end

        p = $color ? $CPROMPT : $PROMPT
        cmd = readline("#{p}", TRUE)
      rescue Interrupt
        puts "Caught ^C, use 'quit' or 'q' to exit"
      rescue
        STDERR.puts "Error encountered: #{$!}"
      end

      # Check for our pipes, split our cmd into regular cmd and pipeout if
      # we find one
      unless cmd.nil?
        if cmd =~ /((\||<|>)+)/
          token = $1
          n = cmd.split(token)
          cmd = n[0].dup.strip
          pipeout = n[1].dup.strip

          if token == "|"
            ## Regular File.open will *NOT* open pipes, Kernel.open will
            fd = Kernel.open("#{token} #{pipeout}","w")
            STDOUT.reopen(fd)
          elsif token == ">"
            STDOUT.reopen("#{pipeout}", "w")
          elsif token == ">>"
            STDOUT.reopen("#{pipeout}", "a")
          else
            STDERR.puts "Err...haven't implemented '<' yet."
            next
          end
        end
      end

      ## Split the command into function and arguments
      unless cmd.nil?
        cmd.gsub!(/(\w)\s([\s\S]*)/) { $1 }
        cmd.chomp!
        args = $2
        args.strip! unless args.nil?
        
        ## Check our aliases and substitute if any match
        cmd, args = NSM_Alias.resolve(cmd, args)

        begin
          Logger.write("[nsmcmd] #{cmd} #{args}\n")
          History.write("#{cmd} #{args}")
          CommandManager.execute(cmd,args) unless cmd.length < 1
        rescue Interrupt
          puts "Caught ^C, use 'quit' or 'q' to exit"
        rescue LocalJumpError
          ## Ignore LocalJumpErrors, it just means we returned
          # I need to find a better way to do this, otherwise I'm
          # just catching premature returns and ignoring them, which
          # isn't exactly what I want to be doing.
        rescue NoMethodError
          # NoMethodError means CommandManager couldn't find the
          # command block for the cmd string.
          puts "Command '#{cmd}' unrecognized. Try 'help' for a list of commands."
        rescue
          STDERR.puts "Error encountered: #{$!}"
          STDERR.puts "Backtrace:"
          STDERR.puts $!.backtrace
        end
      end

      # restore STDOUT if it's different
      STDOUT.reopen($DEF_STDOUT) if STDOUT != $DEF_STDOUT

    }
  end

end

