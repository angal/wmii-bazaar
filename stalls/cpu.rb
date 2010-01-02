#
#   cpu.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Cpu < WmiiStall
  def build
    attach_task(1,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
    @widget.value = freq_format
    #--- cpu time
    @old_cpus = Hash.new
    @widget_cpu0_time = add_widget(WmiiWidget.new("#{@name}_time0"))
    @widget_cpu0_time.value = delta_cpu_time_format(0)
    @widget_cpu0_time.border_color = @wmii_bar.default_focus_border_color
  end
  
  def update
    @widget.value = freq_format
    @widget_cpu0_time.value = delta_cpu_time_format(0)
    refresh_widget(@widget)
    refresh_widget(@widget_cpu0_time)
  end
  
  def freq_format
    num,str = freq.split
    "%s #{str}".%(num)
  end

  def freq
    res = 0
    open("|cpufreq-info -fm","r"){|f|
       res = f.read.strip
    }
    res
  end
  
  def delta_cpu_time_format(_num=0)
    "%03d".%(delta_cpu_time(_num))
  end
  
  def delta_cpu_time(_num=0)
    cpu = "cpu#{_num}"
    ret = 0
    if @old_cpus[cpu].nil?
      @old_cpus[cpu] = cpu_time(_num)
    else
      new_time = cpu_time(_num)
      ret = new_time - @old_cpus[cpu]
      @old_cpus[cpu] = new_time
    end
    ret     
  end

  def cpu_time(_num=0)
    cpu = "cpu#{_num}"
    ret = 0
    open("|grep cpu0 /proc/stat | awk '{print $2+$3+$4}'","r"){|f|
       ret = f.read.to_i
    }
    ret     
  end
end