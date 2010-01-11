#
#   biff.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Biff < WmiiStall
  def build
    attach_task(30,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    @blinking = false
    update
  end
  
  def start_blink
    return if @blinking
    @id_blink = attach_task(1,self,:update_blink)
    @blinking = true
  end

  def stop_blink
    return if !@blinking
    detach_task(@id_blink) if @id_blink
    @blinking = false
  end
  
  def update_blink
    if @widget.foreground_color == @wmii_bar.default_foreground_color
      @widget.foreground_color = @wmii_bar.default_focus_foreground_color
    else
      @widget.foreground_color = @wmii_bar.default_foreground_color
    end
    refresh_widget(@widget)
  end
  
  def update
    num = check_mail
    @widget.value = "*** [#{num}] NEW MAIL ***"
    if num >= 1
      show_widget(@widget)
      refresh_widget(@widget)
      start_blink if !@blinking
    elsif num == 0 && @widget.visible
      stop_blink if @blinking
      hide_widget(@widget) 
      @widget.foreground_color = @wmii_bar.default_foreground_color
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