#
#   disks.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Disks < WmiiStall
  def build
    @disks = Hash.new
    refresh_disks    
    refresh_values    
    attach_task(20,self,:refresh_values)
    attach_task(5,self,:refresh_disks)
  end

  def refresh_disks
    adisks = Array.new
    open(%Q{|df | awk '/dev/ { print $1}'},"r"){|f|
       adisks = f.read.strip.split
    }
    adisks.delete_if{|x| x=='none'||x=='tmpfs'}
    # aggiungo gli eventuali dischi aggiuntivi
    adisks.each{|d|
      if @disks.has_key?(d)
        @disks[d]['label']=File.basename(d)
      else
        @disks[d]=Hash.new
        @disks[d]['label']=File.basename(d)
        @disks[d]['widget']=add_widget(WmiiWidget.new("#{@name}_#{@disks[d]['label']}"))
        @disks[d]['widget'].border_color = @wmii_bar.default_focus_border_color
        refresh_value(d)
      end
    }
    # elimino gli eventuali dischi smontati
    @disks.each_key{|d|
      if !adisks.include?(d)    
        remove_widget(@disks[d]['widget'])
        @disks.delete(d)
      end
    }
  end
 
  def refresh_value(_disk)
    res=Array.new
    open(%Q{|df -h #{_disk} | awk '/dev/ { print $3 "-" $2 "-" $4 "-" $5 "-" $6}'},"r"){|f|
       res = f.read.strip.split('-')
    }
    @disks[_disk]['used']=res[0][0..-2].to_i
    @disks[_disk]['tot']=res[1][0..-2].to_i
    @disks[_disk]['res']= res[2][0..-2].to_i
    @disks[_disk]['um']=res[2][-1..-1]
    @disks[_disk]['perc']=res[3][0..-2].to_i
    @disks[_disk]['point']=res[4]
    @disks[_disk]['widget'].value="#{@disks[_disk]['label']}(#{@disks[_disk]['point']}): #{@disks[_disk]['res']}#{@disks[_disk]['um']} (#{@disks[_disk]['perc']}%)"   
    if @disks[_disk]['perc'] > 90
      @disks[_disk]['widget'].foreground_color = @wmii_bar.default_focus_border_color
    else
      @disks[_disk]['widget'].foreground_color = @wmii_bar.default_foreground_color
    end
    refresh_widget(@disks[_disk]['widget'])
  end
 
  def refresh_values
    @disks.each_key{|d|
      refresh_value(d)
    }
  end
  
  
end



#class Mydisk1 < WmiiTask
#  def build
#    attach_task(20,self,:update)
#    @widget = add_widget(WmiiWidget.new(@name))
#    @widget.border_color = @wmii_bar.default_focus_border_color
#    @d_values = Hash.new
#    update
#  end
# 
#  def update
#    refresh_values
#    @widget.value = "sda3: #{@d_values['res']}#{@d_values['um']} (#{@d_values['perc']})"   
#    refresh_widget(@widget)
#  end
#
#  def refresh_values
#    res = Array.new
#    open(%q{|df -h /dev/sda3 | awk '/\/dev\/sda3/ { print $3 "-" $2 "-" $5}'},"r"){|f|
#       res = f.read.strip.split('-')
#    }
#    @d_values['used']=res[0][0..-2].to_i
#    @d_values['tot']=res[1][0..-2].to_i
#    @d_values['um']=res[0][-1..-1]
#    @d_values['res']= @d_values['tot']-@d_values['used']
#    @d_values['perc']=res[2]
#  end
#end