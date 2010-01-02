#
#   cmdout.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Cmdout < WmiiStall
  def build
    attach_task(conf('gap').to_i,self,:update)
    attach_listener(self, @name)
    attach_listener(self, "Mod1-f")
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    update
  end
  
  def update
    @widget.value = "#{conf('label')}#{self.cmdoutput}" 
    refresh_widget(@widget)
  end
  
  def on_wmii_event(_event)
    case _event.sign
      when "RightBarClick1"
        system('urxvt')        
    end
    #@widget.value = _event.sign 
    #refresh_widget(@widget)
  end
  
  def cmdoutput
    ret = ""
    open("|#{conf('cmd')}","r"){|f|
      ret = f.read.strip
    }
    ret
  end  
end