# vim: set ts=2 sw=2 tw=80
## The NSM_Alias class simply keeps track of all the
## defined aliases and provides methods to update, add
## delete, query or unalias an alias

class NSM_Alias
  ## Retreive an alias by it's name
  def NSM_Alias.get_alias(name)
    @aliases = {} if @aliases.nil?
    return @aliases[name]
  end

  ## Set a new alias or update an existing one
  def NSM_Alias.set_alias(name,val)
    puts "setting alias #{name} -> #{val}"
    @aliases = {} if @aliases.nil?
    @aliases[name.to_s] = val.to_s
  end
  
  ## Delete an alias
  def NSM_Alias.del_alias(name)
    @aliases = {} if @aliases.nil?
    @aliases.delete(name)
  end

  ## Get a hash of the current aliases
  def NSM_Alias.get_aliases
    @aliases = {} if @aliases.nil?
    return @aliases
  end
  
  ## Return an array of alias names
  def NSM_Alias.get_alias_names
    results = []
    @aliases.each { |k,v|
      results.push(k)
    }
    return results
  end

  ## Generate a new command and arguments (resolve alias)
  # returns: cmd, args
  def NSM_Alias.resolve(cmd, args)
    puts "de-aliasing #{cmd}"
    a = self.get_alias(cmd)
    puts "got alias: #{a}"
    unless a.nil?
      newcmd = String.new(a)
      newcmd.gsub!(/(\w)\s([\s\S]*)/) { $1 }
      newcmd.chomp!
      ## We concatinate our old args with the args from the alias
      unless args.nil?
        unless $2.nil?
          newargs = $2 + " " + args
        else
          newargs = args
        end
        newargs.strip!
        return newcmd, newargs
      else
        return newcmd, $2.to_s.strip
      end
    end
    # just return what we already have if it doesn't have an alias
    return cmd, args
  end

end
