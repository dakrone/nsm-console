# vim: set ts=2 sw=2 tw=80
# Class used to keep track of commands for the 'history' command
class History
  @@history = []

  def History.write(line)
    @@history.push(line.to_s)
  end

  def History.print
    i = 1
    @@history.each { |h|
      puts "#{i}\t- #{h.to_s}"
      i = i + 1
    }
  end

end
