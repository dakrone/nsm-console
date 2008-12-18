# vim: set ts=2 sw=2 tw=80
## Command Manager handles all the 'registered' commands in the commands.rb file
## This makes for a much cleaner way to add methods without having to 'eval'
## everything
class CommandManager
  ## The list of our commands
  @@commands = {}
  
  # Add a command to the command array
  def CommandManager.add(command)
    @@commands[command.exec] = command
  end
  
  # Attempt to execute a command, given the name and arguments
  def CommandManager.execute(exec, *args)
    @@commands[exec].execute args
  end
  
  # Return all commands
  def CommandManager.get_commands
    return @@commands
  end
  
  # Return all commands available as an array
  def CommandManager.get_commands_as_array
    cmds = []
    i = 0
    CommandManager.get_commands.each { |k, val|
      cmds[i] = val.exec.to_s
      i += 1
    }
    return cmds
  end
  
end

# Class encapsulating an NSM-Console "command"
class Command
  attr_reader :desc, :exec

  def initialize (desc, exec, block)
    @desc, @exec, @block = desc, exec, block
  end
  
  ## Actually call the block of code
  def execute (*args)
    @block.call args
  end
end

# Override the kernel commands to add 'command', which let's us declare new
# commands in block syntax
module Kernel
  ## In the kernel module, we redefine "command" so we can use it to declare commands
  def command (desc, exec, &block)
    CommandManager.add(Command.new(desc, exec, block))
  end
end

