#
#   timedate.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

class Timedate < WmiiStall
  def build
    attach_task(1,self,:update)
    @widget = add_widget(WmiiWidget.new(@name))
    @widget.border_color = @wmii_bar.default_focus_border_color
  end
  def update
    t = Time.now
    @widget.value = t.strftime("#{conf('format')}") 
    refresh_widget(@widget)
  end
end