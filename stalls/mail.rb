#
#   mail.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Mail < WmiiStall
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

    # echo "x" |mail | grep "^>N\|^>U"|awk '{print $2}'
  end

  def check_mail
    res = 0
    open(%q{|echo "x" |mail | grep "^>N\|^>U\|^ N\|^ U"|wc -l},"r"){|f|
       res = f.read.strip.to_i
    }
    res
  end

  def last_from
    res = ""
    open(%q{|echo "x" |echo "x" |mail | grep "^>N\|^>U"|awk '{print $2}'},"r"){|f|
       res = f.read.strip
    }
    res
  end	  

end