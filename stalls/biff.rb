#
#   biff.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Biff < WmiiStall
  def build
    attach_task(30,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
#    @blinking = false
    update
  end
  
#  def start_blink
#    return if @blinking
#    @start_fg=@widget.foreground_color
#    @start_bg=@widget.background_color
#    @on_fg=@wmii_bar.default_focus_foreground_color
#    @on_bg=@wmii_bar.default_background_color
#    @off_fg=@wmii_bar.default_foreground_color
#    @off_bg=@wmii_bar.default_background_color
#    @blink_on=false
#    @id_blink = attach_task(1,self,:update_blink)
#    @blinking = true
#  end
#  
#  def update_blink_colors(_on_fg,_on_bg,_off_fg,_off_bg)
#    @on_fg=_on_fg
#    @on_bg=_on_bg
#    @off_fg=_off_fg
#    @off_bg=_off_bg
#  end
#  
#  def stop_blink
#    return if !@blinking
#    detach_task(@id_blink) if @id_blink
#    @blinking = false
#    @widget.foreground_color=@start_fg
#    @widget.background_color=@start_bg
#    refresh_widget(@widget)
#  end
#  
#  def update_blink
#    if @blink_on
#      @widget.foreground_color = @off_fg
#      @widget.foreground_color = @off_bg
#      @blink_on=false
#    else
#      @widget.foreground_color = @on_fg
#      @widget.background_color = @on_bg
#      @blink_on=true
#    end
#    refresh_widget(@widget)
#  end
  
  def update
    num = check_mail
    @widget.value = "*** [#{num}] NEW MAIL ***"
    if num >= 1
      show_widget(@widget)
      refresh_widget(@widget)
      @widget.start_blink if !@widget.blinking?
    elsif num == 0 && @widget.visible
      @widget.stop_blink if @widget.blinking?
      hide_widget(@widget) 
      #@widget.foreground_color = @wmii_bar.default_foreground_color
    end
    @last_num = num
  end

  def check_mail
    res = 0
    open(%Q{|chk4mail #{File.expand_path(conf('mbox'))} |awk '{print $2}'},"r"){|f|
       res = f.read.strip.to_i
    }
    res
  end

end