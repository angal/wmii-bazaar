#
#   wall.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Wall < WmiiStall
  def build
    @border_color = @wmii_bar.default_focus_border_color
    attach_task(conf('gap').to_i,self,:update)
  end

  def check
    true  
  end
 
  def update
   files = Array.new
   files = Dir["#{File.expand_path(conf('dir'))}/*"].sort
   files.delete_if {|f| File.stat(f).directory?}
   selected_file = files[rand(files.length)]
   #system("feh --bg-scale #{selected_file}")
   system_send("feh --bg-center #{selected_file}")
  end
end