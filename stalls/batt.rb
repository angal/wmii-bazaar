#
#   batt.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Batt < WmiiStall
  def build
    @max_capacity = full_capacity
    @progress_count = 0
    @progress_max = 2
    @level=100
    @alert_level = conf("alert_level").to_i
    attach_task(10,self,:update_charging_state)
    attach_task(1,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    update_charging_state
    update
  end
  
  def check
    File.exists?("#{self.conf('info_dir')}/info")
  end
  
  def progress(_side='left')
    if @progress_count >= @progress_max
      @progress_count=1
    else
      @progress_count=@progress_count+1
    end
    if _side == 'left'
      _char='<'
    else
      _char='>'
    end
    str=''
    @progress_count.times{str << _char}
    if _side == 'left'
      return str.rjust(@progress_max)
    else
      return str.ljust(@progress_max)
    end
    #ret = "%#{@progress_max}s".%(str)
  end
  
  def update
    if @last_c_state == 'charged' && @widget.visible
      hide_widget(@widget)
    elsif @last_c_state != 'charged' && !@widget.visible
      show_widget(@widget)
    end
    if @widget.visible
      @widget.value = build_value(@last_c_state, @level)
#      if @level < @alert_level && !@widget.blinking?
#        @widget.start_blink_with_colors(conf('alert_fg'),conf('alert_bg'),@wmii_bar.default_background_color,@wmii_bar.default_background_color)
#      elsif @level >= @alert_level && @widget.blinking? 
#        @widget.stop_blink 
#      else
        refresh_widget(@widget) if !@widget.blinking?
#      end
    end
  end
  
  def build_value(_c_state, _level)
    suf="BATT"
    if _c_state == 'charging'
      suf="#{suf} #{progress('right')} "
    elsif _c_state == 'charged'
      suf="#{suf} <> "
    else
      suf="#{suf} #{progress('left')} "
    end
    suf+"%3d".%(_level)+' %'    
  end
  
  def update_charging_state
    c_state = charging_state
    if !@widget.blinking?
      if c_state == 'charging'
        @widget.background_color = conf('charging_bg')
        @widget.foreground_color = conf('charging_fg')
      elsif c_state == 'charged'
        @widget.background_color = @wmii_bar.default_background_color
        @widget.foreground_color = @wmii_bar.default_foreground_color
      else
        @widget.background_color = conf('uncharging_bg')
        @widget.foreground_color = conf('uncharging_fg')
      end
    end
    if c_state != 'charged' || c_state !=@last_c_state 
      @level = (cur_capacity * 100 / @max_capacity)
      @widget.value = build_value(c_state, @level)
      if @level < @alert_level && !@widget.blinking? && c_state != 'charging'
        @widget.start_blink_with_colors(conf('alert_fg'),conf('alert_bg'),@wmii_bar.default_background_color,@wmii_bar.default_background_color)
      elsif (@level >= @alert_level || c_state == 'charging') && @widget.blinking? 
        @widget.stop_blink 
      end
      
#      if c_state != 'charged'
#        if @level < 50
#          @widget.foreground_color = "#d90e10"
#        else
#          @widget.foreground_color = "#28be49"
#        end
#      end
    end
    @last_c_state=c_state
  end
  
  def full_capacity
    res = 0
    open("|grep #{'"'}last full capacity:#{'"'} #{self.conf('info_dir')}/info | awk '{print $4}'","r"){|f|
       res = f.read.strip.to_i
    }
    res
  end

  def cur_capacity
    res = 0
    open("|grep #{'"'}remaining capacity:#{'"'} #{self.conf('info_dir')}/state | awk '{print $3}'","r"){|f|
       res = f.read.strip.to_i
    }
    res
  end
  
  def charging_state 
    res = ''
    open("|grep #{'"'}charging state:#{'"'} #{self.conf('info_dir')}/state | awk '{print $3}'","r"){|f|
       res = f.read.strip
    }
    res
  end
end