#
#   wall.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Wall < WmiiStall
  def build
    @border_color = @wmii_bar.default_focus_border_color
    if conf('type')=='random'
      attach_task(conf('random.gap').to_i,self,:update)
    elsif conf('type')=='workspace'
      @view_actions = Hash.new
      views = conf('workspace.bind.views').split(',')
      views.each{|view|
        img = conf("workspace.bind.views.#{view}.img")
        command = conf("workspace.bind.views.#{view}.command")
        if img
          @view_actions[view]="feh --bg-center #{img}"
          attach_listener(self,view)
        elsif command
          @view_actions[view]=command
          attach_listener(self,view)
        end
      }
      selected_view=Wmiir::selected_tag
      sel_img=conf("workspace.bind.views.#{selected_view}.img")
      if sel_img
        system_send("feh --bg-center #{sel_img}")
      end
    end
  end

  def check
    if conf('type')
      File.exists?(File.expand_path(conf('dir')))
    else
      false
    end
  end
 
  def update
    system_send("feh --bg-center #{random_file}")
  end

  def random_file
    files = Array.new
    files = Dir["#{File.expand_path(conf('dir'))}/*"].sort
    files.delete_if {|f| File.stat(f).directory?}
    selected_file = files[rand(files.length)]
    selected_file
  end

  def on_wmii_event(_event)
    if _event.sign == "FocusTag"
      if @view_actions[_event.sender]
        system_send(@view_actions[_event.sender])  
      end
    end
  end
  
end