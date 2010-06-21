#
#   wmii-bazaar.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#

require "observer"
require "open3"
Dir.chdir("#{File.dirname(__FILE__)}")
  module LogLevel
    FATAL=5
    ERROR=4
    WARN=3
    INFO=2
    DEBUG=1
    TRACE=0
    def LogLevel.level_string(_level)
      case _level
        when 5
          return "FATAL"
        when 4
          return "ERROR"
        when 3
          return "WARN"
        when 2
          return "INFO"
        when 1
          return "DEBUG"
        when 0
          return "TRACE"
      end
    end
  end

  class Wmiir
    def Wmiir::system_send(_cmd)
      to_ret = ''
      Open3.popen3(_cmd){|stdin, stdout, stderr|
        stdout.each do |line|
          to_ret = to_ret+line
        end 
      }
      to_ret
    end

    def Wmiir::read(_path)
      system_send("wmiir read #{_path}")
    end

    def Wmiir::ls(_path)
      system_send("wmiir ls #{_path}")
    end
  
    def Wmiir::selected_client
      read('/client/sel/ctl').split[0]
    end

    def Wmiir::selected_tag
      read('/tag/sel/ctl').split[0]
    end

    def Wmiir::element_in_path?(_path, _element)    
      ls(_path).split.include?(_element)
    end
    
    def Wmiir::create_tag(_tag, _colors)
      system_send(%Q{echo "#{_colors}" "#{_tag}" | wmiir create "/lbar/#{_tag}"})
    end
    
  end
  
  class WmiiBazaar
    BAR_NAME = "___WMII_SPACE___"
    attr_reader :widgets
    attr_reader :default_foreground_color
    attr_reader :default_background_color
    attr_reader :default_border_color
    attr_reader :default_focus_foreground_color
    attr_reader :default_focus_background_color
    attr_reader :default_focus_border_color
    attr_reader :exports
    attr_reader :controller
    def initialize(_controller)
      @controller=_controller
      @exports=_controller.conf_group('export')
      defaulting
      system_send("set -- $(echo '#{@exports['WMII_NORMCOLORS']}' '#{@exports['WMII_FOCUSCOLORS']}')")
      #system("wmiir remove /rbar/#{BAR_NAME} 2>/dev/null")
      #system("echo #{'"'}#{trans_tuple_color}#{'"'} | wmiir create /rbar/#{BAR_NAME} 2>/dev/null")
      @widgets = Array.new
      remove_widget(@space_widget) if @space_widget
      @space_widget= add_widget(WmiiWidget.new(BAR_NAME))
      remove_widget(WmiiWidget.new('status'))
    end
    
    def system_send(_cmd,_info="WmiiBazaar")
      @controller.system_send(_cmd,_info)
    end
    
    def trans_tuple_color
      "#{@default_foreground_color} #{@default_foreground_color} #{@default_foreground_color}"
    end
    
    def alive?
      system("wmiir read /rbar/#{BAR_NAME} 1>/dev/null")
    end
    
    def defaulting
      a = Array.new
      a = @exports['WMII_NORMCOLORS'].strip.split
#      open("|echo $WMII_NORMCOLORS","r"){|f|
#         a = f.read.strip.split
#      }
      @default_foreground_color = a[0]
      @default_background_color = a[1]
      @default_border_color = a[2]
      a = Array.new
      a = @exports['WMII_FOCUSCOLORS'].strip.split
#      open("|echo $WMII_FOCUSCOLORS","r"){|f|
#         a = f.read.strip.split
#      }
      @default_focus_foreground_color = a[0]
      @default_focus_background_color = a[1]
      @default_focus_border_color = a[2]
    end
    
    def normalize(_widget)
      if _widget.foreground_color.nil?
        _widget.foreground_color = @default_foreground_color
      end
      if _widget.background_color.nil?
        _widget.background_color = @default_background_color
      end
      if _widget.border_color.nil?
        _widget.border_color = @default_border_color
      end
    end
    
    def widget_colors(_widget)
      "#{_widget.foreground_color} #{_widget.background_color} #{_widget.border_color}"
    end
    
    def add_widget(_widget)
      _widget.bazaar=self
      normalize(_widget)
      show_widget(_widget)
      @widgets << _widget
      _widget
    end
    
    def update_widget(_widget)
      system_send("echo #{'"'}#{widget_colors(_widget)}#{'"'} #{'"'}#{_widget.value}#{'"'}|wmiir write /rbar/#{_widget.name}")
    end
    
    def remove_widget(_widget)
      hide_widget(_widget)
      @widgets.delete(_widget)
    end
    
    def hide_widget(_widget)
      system_send("wmiir remove /rbar/#{_widget.name} 2>/dev/null")
      _widget.visible = false
    end

    def show_widget(_widget)
      cmd = "echo #{'"'}#{widget_colors(_widget)}#{'"'} #{'"'}#{_widget.value}#{'"'}|wmiir create /rbar/#{_widget.name}"
      system_send(cmd)
      _widget.visible = true
    end
    
    def finalize
      @widgets.each{|w| system("wmiir remove /rbar/#{w.name} 2>/dev/null")}
      system("wmiir remove /rbar/#{BAR_NAME} 2>/dev/null")
    end
  end

class WmiiEvent
  attr_reader :sender
  attr_reader :time
  attr_reader :sign
  #attr_reader :arg
  attr_reader :raw
  def initialize(_event_str)
    @raw = _event_str
    ae=_event_str.strip.split
    if ae.length > 2 && ae[0][0..5] == 'Client'
      @sign = ae[0].concat(ae[-1])
      @sender = ae[1]
    elsif ae.length > 2
      @sign = ae[0..1].join
      @sender = ae[2]
    elsif ae.length > 0
      @sign = ae[0]
      @sender = ae[1]
    end
    @time = Time.new
  end
  
  def add_finalize_callback(_proc)
    ObjectSpace.define_finalizer(self, _proc) 
  end
end

#class WmiiConfigApi
#  def initialize(_controller)
#    @wmii_controller=_controller
#  end
#  def widget(_name)
#    @wmii_controller.twidgets[_name]
#  end
#end

class ListenerCallback
  attr_reader :listener
  def initialize(_listener, _method=:on_wmii_event)
  		@listener = _listener
  		@method=_method
  end
    
  def respond_to?(_method)
    if _method == :on_wmii_event 
      @listener.respond_to?(@method)
    else
      super
    end
  end
    
  def on_wmii_event(*args)
  		@listener.send(@method,*args) if @listener.respond_to?(@method)
  end
end


class WmiiBazaarController
  include Observable
  attr_reader :stalls
  STOP_EVENT = "___STOP_EVENT___"
  def initialize
    @stopping=false
    load_config
    _local_dir = File.expand_path(conf('home.dir')) 
    if _local_dir && !File.exist?(_local_dir)
      Dir.mkdir(_local_dir)
      @first_run = true
    end
    #@config_api = WmiiConfigApi.new(self)
    attach_listener(self,STOP_EVENT)
  end
  
  def on_wmii_event(_event)
    case _event.sender
      when STOP_EVENT, "Quit"
        @stopping=true
    end
  end

  def start(_bazaar)
    log(self,"start WmiiBazaarController",LogLevel::INFO)
    @bazaar=_bazaar
    @stalls_list=conf('stalls.list').split(',').collect!{| wi | wi.strip}
    @stalls_dir= "#{Dir.pwd}/#{self.conf('stalls.dir')}"
    @stalls_dir_local="#{File.expand_path(conf('home.dir'))}/#{self.conf('stalls.dir')}"
    @stalls=Hash.new
    @tasks=Array.new
    @task_id = 0
    event_handler
    load_stalls
  	 mainloop
  end
  
  def conf(_property)
    @props[_property]
  end
  
  def conf_group(_group)
    @conf_groups = Hash.new if !defined?(@conf_groups)
    if @conf_groups[_group].nil?
      @conf_groups[_group] = Hash.new
      glen=_group.length
      @props.keys.sort.each{|k|
        if k[0..glen] == "#{_group}."
          @conf_groups[_group][k[glen+1..-1]]=@props[k]
        elsif @conf_groups[_group].length > 0
          break
        end
      }
    end
    @conf_groups[_group]
  end

  def system_send(_cmd, _info="exec")
    to_ret = ''
    error = ''
    Open3.popen3(_cmd){|stdin, stdout, stderr|
      stdout.each do |line|
        to_ret = to_ret+line
      end 
      stderr.each do |line|
        error+=line
      end 
    }
    log(@name, "on #{_info}: #{_cmd} execution : #{to_ret}",LogLevel::TRACE)
    if error && error.strip.length > 0
      log(@name, "on #{_info}: #{_cmd} execution : #{error}",LogLevel::ERROR)
    end
    to_ret
  end
  
  
  def log(_caller, _msg, _level=LogLevel::TRACE)
#    if @thread_log && @thread_log.alive?
#      @thread_log.join
#    end
#    @thread_log = Thread.new do
      if _level >= conf('log.level').to_i
        log_file = File.expand_path(conf('log.file'))
        if !File.exists?(log_file)
          File.new(log_file, File::CREAT).close
        end
        if FileTest::exist?(log_file) && File.stat(log_file).writable?
          f = File.new(log_file, "a")
          begin
            if f
              f.syswrite(Time.new.strftime("#{LogLevel.level_string(_level)} at %a %d-%b-%Y %H:%M:%S : #{_caller} : #{_msg}\n"))
            end
          ensure
            f.close unless f.nil?
          end
        end
      end
#    end
  end  

  def load_config_from_file(_property_file, _hash)
    if _property_file &&  FileTest::exist?(_property_file)
      f = File::open(_property_file,'r')
      begin
        _lines = f.readlines
        _lines.each{|_line|
          _strip_line = _line.strip
          if (_strip_line.length > 0)&&(_strip_line[0,1]!='#')
            var = _line.split('=')
            if var.length > 1
              _value = var[1].strip
              var[2..-1].collect{|x| _value=_value+'='+x} if var.length > 2
              _hash[var[0].strip]=_value
            end
          end
        }
      ensure
        f.close unless f.nil?
      end
    end
    _hash
  end
  
  def load_config
    @property_file=__FILE__.sub(".rb",".conf")
    @props = load_config_from_file(@property_file, Hash.new)
    @global_props=Hash.new.update(@props)
    @local_property_file="#{File.expand_path(conf('home.dir'))}/#{File.basename(@property_file)}"
    @props = load_config_from_file(@local_property_file, @props)
    if !FileTest::exist?(@local_property_file)
      if !FileTest::exist?(File.expand_path(conf('home.dir')))
        Dir.mkdir(File.expand_path(conf('home.dir')))
      end
      f = File.new(@local_property_file, "w+")
      begin
        File.open(@property_file) do |input|
          input.readlines.each{|line|
            if line.strip.length > 0
              line = "#"+line
            end
            f.syswrite(line)
          }
        end
      ensure
        f.close unless f.nil?
      end
    end
    
    # -- reash
    # inherited 
    @props.each{|key,value|
      new_value=sub_from_hash(value,@global_props,"@@{")
      if new_value[0..0]=='!'
        open("|#{new_value[1..-1]}","r"){|f|
          new_value = f.read.strip
        }
      end
      new_key=sub_from_hash(key,@global_props,"@@{")
      @props[new_key]=new_value
      if new_key != key
        @props.delete(key)
      end
    }
    # contextual
    @props.each{|key,value|
      new_value=sub_from_hash(value,@props)
      if new_value[0..0]=='!'
        open("|#{new_value[1..-1]}","r"){|f|
          new_value = f.read.strip
        }
      end
      new_key=sub_from_hash(key,@props)
      @props[new_key]=new_value
      if new_key != key
        @props.delete(key)
      end
    }
  end

  def sub_from_hash(_value,_hash,_left_sep="@{",_right_sep="}")
    new_value = _value
    while new_value.include?(_left_sep)
      key_to_find = new_value.split(_left_sep)[1].split[0]
      if key_to_find.include?(_right_sep)
        key_to_find= key_to_find.split(_right_sep)[0]
        key_to_find_with_sep= "#{_left_sep}#{key_to_find}#{_right_sep}"
      end
      if _hash[key_to_find]
        to_sub = _hash[key_to_find]
      else
        to_sub = "<KEY '#{key_to_find}' NOT FOUND!"
      end
      new_value=new_value.sub(key_to_find_with_sep,to_sub)
    end
    new_value
  end

  def load_stalls
    @stalls_list.each{|stall_name|
      stall_base_name=stall_name.split("@@@")[0]
      file_local = "#{@stalls_dir_local}/#{stall_base_name}.rb"
      file_etc = "#{@stalls_dir}/#{stall_base_name}.rb"
      if File.exists?(file_local)
        file = file_local
      elsif File.exists?(file_etc)
        file = file_etc
      else
        log(self,"Stall <<#{stall_name}>> not found!",LogLevel::ERROR)
        next
      end
      eval("require '#{file}'") 
      class_name = stall_base_name.capitalize
      stall = eval(class_name).new(self, @bazaar, stall_name)
      @stalls[stall_name]=stall
      if stall.check
        stall.build
      end
    }
  end


  def add_widget(widget)
    @bazaar.add_widget(widget)
  end

  def remove_widget(widget)
    @bazaar.remove_widget(widget)
  end

  def hide_widget(widget)
    @bazaar.hide_widget(widget)
  end
  
  def show_widget(widget)
    @bazaar.show_widget(widget)
  end

  def refresh_widget(_widget)
    @bazaar.update_widget(_widget)
  end

  def new_task
    @task_id = @task_id+1
    @task_id
  end

  def attach_task(_gap=1, _worker=nil, _method=:update)
    task_id = new_task
    @tasks<<{:task_id=>task_id,:gap =>_gap,:worker =>_worker, :method =>_method, :count=>0}
    task_id
  end

  def detach_task(_task_id=nil)
    @tasks.delete_if {|x| x[:task_id] == _task_id }
  end

  def mainloop
    j=0
    unit = 1
    loop {
      j=j+unit
      @tasks.each{|t|
        t[:count]=t[:count]+1
        if t[:count] >= t[:gap]
          t[:count] = 0
          Thread.new do
            begin
              #log(t[:task_id],"Mainloop task => #{t[:worker]}.#{t[:method]}",LogLevel::TRACE) 
              t[:worker].send(t[:method])
            rescue Exception,LoadError
              msg = "on executing Task \"#{t[:worker]}.#{t[:method]}\" (#{$!.class.to_s}) : #{$!} at : #{$@.to_s}"
              log(t[:task_id],msg,LogLevel::ERROR) 
            end
          end
        end
      }
      break if @stopping || !@bazaar.alive? #|| j>=5 
      sleep(unit)
    }
 	  finalize
  end
  
  def attach_listener(_listener, _sender='*all', _method = :on_wmii_event)
    @listeners = {} unless defined? @listeners
    @listeners[_sender] = []   unless @listeners.has_key?(_sender)
    @listeners[_sender] << ListenerCallback.new(_listener, _method)
  end
  
  def detach_listener(_listener, _sender='*all')
    if @listeners[_sender]
      @listeners[_sender].each{|lis|
        if lis.listener == _listener || lis == _listener
          lis_to_del = lis
          break
        end   
      }
      @listeners[_sender].delete(lis_to_del) if lis_to_del
    end
  end

  def event_dispatcher(_event_str)
    event = WmiiEvent.new(_event_str)
    #p event
    listeners = []
    listeners = listeners.concat(@listeners[event.sender]) if @listeners[event.sender]
    listeners = listeners.concat(@listeners['*all']) if @listeners['*all']
    if !listeners.empty?
      listeners.each do|_listener|
        Thread.new{
          begin
            if _listener.respond_to?(:on_wmii_event)
              log(_listener,"Dispatch Event => sender=#{event.sender} sign=#{event.sign}",LogLevel::TRACE) 
              _listener.send(:on_wmii_event, event)
            else
              log(event.sender,"Dispatch Event => sign=#{event.sign} #{event.sender} not respond to : on_wmii_event",LogLevel::WARN) 
            end
          rescue Exception,LoadError
            msg = %{on "#{event.sender}:#{event.sign}" (#{$!.class.to_s}) : #{$!} at : #{$@.to_s}}
            log(_listener,msg,LogLevel::ERROR) 
          end
        }
      end
    end
  end

  def event_handler
    require "open3"
    @eventHandlerThread = Thread.new do
      Thread.current.abort_on_exception = true
      Open3.popen3("wmiir read /event"){|stdin, stdout, stderr|
        stdout.each do |line|
          event_dispatcher(line)
        end 
      }
    end
  end
  
  def finalize
    Thread.kill(@eventHandlerThread) if @eventHandlerThread
    @listeners.clear
    @tasks.clear
    @bazaar.finalize
  end
  
  def WmiiBazaarController::start
    instance = self.new
    instance.start(WmiiBazaar.new(instance))
  end
  
  def WmiiBazaarController::stop
    system("wmiir xwrite /event #{WmiiBazaarController::STOP_EVENT}")
    #system("wmiir remove /rbar/#{WmiiBazaar::BAR_NAME} 2>/dev/null")
  end

  def WmiiBazaarController::restart
    WmiiBazaarController::stop
    WmiiBazaarController::start
  end

end

class WmiiWidget
  attr_accessor :value
  attr_accessor :foreground_color
  attr_accessor :background_color
  attr_accessor :border_color
  attr_accessor :visible
  attr_accessor :bazaar
  attr_reader :name
  def initialize(_name)
    @name = _name
    @visible = false
    @blinking = false
  end
  # blinking capability
  def blinking?
    @blinking
  end
  
  def start_blink_with_colors(_on_fg,_on_bg,_off_fg,_off_bg)
    return if @blinking
    @start_fg=@foreground_color
    @start_bg=@background_color
    @on_fg=_on_fg
    @on_bg=_on_bg
    @off_fg=_off_fg
    @off_bg=_off_bg
    @blink_on=false
    @id_blink = @bazaar.controller.attach_task(1,self,:update_blink)
    @blinking = true
  end
  
  def start_blink
    start_blink_with_colors(@bazaar.default_focus_foreground_color, @bazaar.default_background_color, @bazaar.default_foreground_color, @bazaar.default_background_color)
  end  
  
  def update_blink_colors(_on_fg,_on_bg,_off_fg,_off_bg)
    @on_fg=_on_fg
    @on_bg=_on_bg
    @off_fg=_off_fg
    @off_bg=_off_bg
  end
  
  def stop_blink
    return if !@blinking
    @bazaar.controller.detach_task(@id_blink) if @id_blink
    @blinking = false
    @foreground_color=@start_fg
    @background_color=@start_bg
    @bazaar.controller.refresh_widget(self)
  end
  
  def update_blink
    if @blink_on
      @foreground_color = @off_fg
      @background_color = @off_bg
      @blink_on=false
    else
      @foreground_color = @on_fg
      @background_color = @on_bg
      @blink_on=true
    end
    @bazaar.controller.refresh_widget(self)
  end
  
end

class WmiiStall
  attr_reader :name
  def initialize(_wmii_controller, _wmii_bar, _name)
    @wmii_controller = _wmii_controller
    @wmii_bar = _wmii_bar
    @name = _name
    handle_conf_event
  end
  
  def handle_conf_event
    @events_callbacks = Hash.new
    on_events_array = conf_group('on_events')
    on_events_array.each{|key,value|
      @events_callbacks[key]=value
    }
    attach_listener(self, "*all", :on_events) if on_events_array.length > 0
  end
  
  def on_events(_event)
    if @events_callbacks[_event.sign]
      cmd = @events_callbacks[_event.sign].sub('_EVENT_.sender',_event.sender).sub('_EVENT_.sign',_event.sign)
      system_or_instance_send(cmd)
    end 
  end

  def system_or_instance_send(_cmd, _info="exec")
    if _cmd[0..0]=="%"
      self.instance_eval(_cmd[1..-1]) if self.respond_to?(_cmd[1..-1])     
    else
      system_send(_cmd, _info)
    end
  end

  def conf(_property)
    @wmii_controller.conf("stalls.conf.#{@name}.#{_property}")
  end

  def conf_group(_group)
    @wmii_controller.conf_group("stalls.conf.#{@name}.#{_group}")
  end

  def global_conf(_property)
    @wmii_controller.conf(_property)
  end

  def global_conf_group(_group)
    @wmii_controller.conf_group(_group)
  end

  def system_send(_cmd, _info="#{@name} exec")
    @wmii_controller.system_send(_cmd, _info)
  end

  def log(_caller, _msg, _level=5)
    @wmii_controller.log(_caller, _msg, _level)
  end
  
  def check
    true
  end
  
  def build
  end
  
  def update
  end
  
  def attach_task(_gap=1, _worker=self, _method=:update)
    @wmii_controller.attach_task(_gap, _worker, _method)
  end

  def detach_task(_task_id=nil)
    @wmii_controller.detach_task(_task_id)
  end
  
  def attach_listener(_listener, _sender='*all', _method = :on_wmii_event)
    @wmii_controller.attach_listener(_listener, _sender, _method)
  end
  
  def detach_listener(_listener, _sender='*all')
    @wmii_controller.detach_listener(_listener, _sender)
  end
  
  
  def refresh_widget(_widget)
    @wmii_controller.refresh_widget(_widget)
  end
  
  def add_widget(_widget)
    @wmii_controller.add_widget(_widget)
  end

  def remove_widget(_widget)
    @wmii_controller.remove_widget(_widget)
  end

  def hide_widget(_widget)
    @wmii_controller.hide_widget(_widget)
  end

  def show_widget(_widget)
    @wmii_controller.show_widget(_widget)
  end

end


#WmiiBazaarController.start