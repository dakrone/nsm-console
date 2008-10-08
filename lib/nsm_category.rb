# vim: set ts=2 sw=2 tw=80
class NSM_Category
  
  def initialize(name,mods)
    @cat_name = name
    @enabled = false
    @modules = mods
  end
  
  def get_name
    return @cat_name
  end
  
  def enabled?
    return @enabled
  end
  
  def dump
    if self.enabled?
      print $color ? "#{$GREEN}[+]#{$RESET} " : "[+] "
    else
      print $color ? "#{$RED}[-]#{$RESET} " : "[-] "
    end
    puts $color ? "#{$BROWN}#{@cat_name}#{$RESET}" : "#{@cat_name}"
  end
  
  def get_modules
    return @modules
  end

  def set_enabled_mods(en)
    if en
      @enabled = true
    else
      @enabled = false
    end
    @modules.each { |mod|
      m = get_mod_by_name(mod)
      m.set_enabled(en) unless m.nil?      
    }
  end

end
