#
#   chkmail.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Biff < WmiiStall
  def build
    attach_task(30,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    @last_num = -1
    update
  end
  
  def start_blink
    @id_blink = attach_task(1,self,:update_blink)
  end

  def stop_blink
    detach_task(@id_blink) if @id_blink
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
    if num >= 1 && num != @last_num
      show_widget(@widget)
      refresh_widget(@widget)
      start_blink
    elsif num == 0 && num != @last_num
      stop_blink
      hide_widget(@widget)
      @widget.foreground_color = @wmii_bar.default_foreground_color
    end
    @last_num = num
  end

  def check_mail
    if @tast
      @tast+=1
    else
      @tast=-1
    end
    if @tast > 0 && @tast < 3
      return @tast
    else
      return 0
    end
    res = 0
    open(%Q{|chk4mail #{File.expand_path(conf('mbox'))} |awk '{print $2}'},"r"){|f|
       res = f.read.strip.to_i
    }
    res
  end

end