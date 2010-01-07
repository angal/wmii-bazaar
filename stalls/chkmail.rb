#
#   chkmail.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Chkmail < WmiiStall
  def build
    attach_task(30,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    update
  end
  
  def update
    num = check_mail
    @widget.value = "N. mail = #{num}"
    if num >= 1
      @widget.background_color = @wmii_bar.default_foreground_color
      @widget.foreground_color = @wmii_bar.default_background_color
      @widget.value= "#{@widget.value} [last from #{last_from}]"  
    elsif num == 0
      @widget.background_color = @wmii_bar.default_background_color
      @widget.foreground_color = @wmii_bar.default_foreground_color
    end
    refresh_widget(@widget)

  end

  def check_mail
    res = 0
    open(%Q{|chk4mail #{File.expand_path(conf('mbox'))} |awk '{print $2}'},"r"){|f|
       res = f.read.strip.to_i
    }
    res
  end

  def last_from
    res = ""
    open(%Q{|echo "x" |echo "x" |mail -f #{File.expand_path(conf('mbox'))} | grep "^>N\|^>U"|awk '{print $2}'},"r"){|f|
       res = f.read.strip
    }
    res
  end	  

end