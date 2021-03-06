#      ("`-''-/").___..--''"`-._
#       `o_ o  )   `-.  (     ).`-.__.`)
#       (_Y_.)'  ._   )  `._ `. ``-..-'
#     _..`--'_..-_/  /--'_.' .'
#    (il).-''  (li).'  ((!.-'
#
#   puppeteer.rb - wmii-bazaar
#   by Antonio Galeone <antonio.galeone@gmail.org>
#


class Puppeteer < WmiiStall
  def build
    attach_listener(self)
    keys_conf
    events_conf
    wm_conf
    apply_rules
    start_init
  end
  
  def start_init
    progs_list
    if @default_view
      system_send(%Q{wmiir xwrite /ctl view "#{@default_view}"}, "Initialization")
    end
    if conf('startup.run')
      Thread.new do
        system_send(conf('startup.run'), "startup.run")
      end
    end
    @work_dir = Dir.pwd
    Dir.chdir("#{File.expand_path('~')}")
  end
  
  def wm_conf
    IO.popen("wmiir write /ctl", "w") do |fkeys|
      fkeys.puts  "font #{@wmii_bar.exports['WMII_FONT']}"
      fkeys.puts  "focuscolors #{@wmii_bar.exports['WMII_FOCUSCOLORS']}"
      fkeys.puts  "normcolors #{@wmii_bar.exports['WMII_NORMCOLORS']}"
      fkeys.puts  "grabmod #{global_conf('MODKEY')}"
      fkeys.puts  "border 1"
    end
  end

  def apply_rules
    # apply  colrules and tagrules
    ['colrules','tagrules'].each{|rule|
      rules = global_conf_group(rule)
      if rules.length > 0
        IO.popen("wmiir write /#{rule}", "w") do |io|
          rules.each{|k,v|
            io.puts  "#{k} -> #{v}"
          }
        end
      end
    }
  end
  
  def keys_conf
    @key_actions = Hash.new
    @tag_views = Array.new
    modkey = global_conf('MODKEY')
    
    modkeys_array = Array.new
    
    if conf('modkey.keys.groups')
      groups = conf('modkey.keys.groups').split(',')
    else
      groups = Array.new
    end
    groups.each{|group|
      group_keys = conf("modkey.keys.#{group}")
      if group_keys
        group_keys_array = group_keys.split(',')
        group_keys_array.collect!{|x|
          xmod = "#{modkey}-#{x.strip}" 
          if conf("modkey.keys.#{group}.#{x.strip}.view")
            @tag_views << conf("modkey.keys.#{group}.#{x.strip}.view")
            @key_actions[xmod]=%Q{wmiir xwrite /ctl view "#{conf("modkey.keys.#{group}.#{x.strip}.view")}"}
            if conf("modkey.keys.#{group}.#{x.strip}.action")
              @key_actions[xmod] = "#{@key_actions[xmod]} && #{conf("modkey.keys.#{group}.#{x.strip}.action")}"
            end
            # ModKey-Shift-key
            xmodshift="#{modkey}-Shift-#{x.strip}"
            modkeys_array << xmodshift 
            @key_actions[xmodshift]=%Q{wmiir xwrite /client/sel/tags "#{conf("modkey.keys.#{group}.#{x.strip}.view")}"}
          else
            @key_actions[xmod]=conf("modkey.keys.#{group}.#{x.strip}.action")
          end
          xmod
        }
        if conf("modkey.keys.#{group}.default")
          @default_view=conf("modkey.keys.#{group}.#{conf("modkey.keys.#{group}.default")}.view")
        end
        modkeys_array.concat(group_keys_array)
      end
    }
    IO.popen("wmiir write /keys", "w") do |fkeys|
      modkeys_array.sort.each{|k|
        fkeys.puts  k
      }
    end
  end

  def events_conf
    @event_actions = Hash.new
    if conf('events')
      events_array = conf('events').split(',')
    else
      events_array = Array.new
    end
    
    events_array.each{|event|
      if conf("events.#{event}.action")
        @event_actions[event]=conf("events.#{event}.action")
      end
    }
  end
  
  def wmiir_read(_path)
    system_send("wmiir read #{_path}")
  end
  
  def selected_client
    selected_client=wmiir_read('/client/sel/ctl').split[0]
  end
  
  def retag_selected_client
    newtag=system_send(%Q{echo ''|#{global_conf('menu')} -h "#{global_conf('history.file')}".tags -n 50}) 
    system_send("wmiir xwrite /client/#{selected_client}/tags #{newtag}")
    @tag_views << newtag
  end
  
  def select_tag
    tags = system_send("wmiir ls /tag").split.collect!{|x|
      x.chop
    }
    tags.delete("sel")
    newtag=system_send(%Q{echo -e "#{tags.join('\n')}"|#{global_conf('menu')} -h "#{global_conf('history.file')}".tags -n 50}) 
    system_send(%Q{wmiir xwrite /ctl view #{newtag}})
  end
  
  def select_client
    left_sep="["
    right_sep="]"
    max_length = 30
    clients = system_send("wmiir ls /client").split.collect!{|x|
      x.chop
    }
    clients.delete("sel")
    labels=[]
    tags=[]
    clients.each{|c|
      label = wmiir_read("/client/#{c}/label")
      if label && label.length > max_length
        label = "#{label[0..max_length-1]} ... "
      end
      labels << %Q{#{left_sep}#{label}#{right_sep}}
      tags << wmiir_read("/client/#{c}/tags")
    }
    newclient=system_send(%Q{echo -e "#{labels.join('\n')}"|#{global_conf('menu')} -h "#{global_conf('history.file')}".tags -n 50}) 
    index = labels.index(newclient)
    if index
      system_send(%Q{wmiir xwrite /ctl view "#{tags[index]}"})
      system_send(%Q{wmiir xwrite /tag/sel/ctl select client #{clients[index]}})
    end
  end
  
  def progs_list
    executables=executables_in_dirs(ENV['PATH'])
    File.open(global_conf("progs.file"), "w") do |file|
      executables.sort.each{|k|
        file.puts  k
      }
    end
  end
  
  def restart
    detach_listener(self)
    Dir.chdir(@work_dir)
    WmiiBazaarController::start
  end
  
  def executables_in_dirs(_dirs) 
    executables = Array.new
    dirs = _dirs.split(':')
    dirs.each{|d|
      if FileTest.exist?(d)
        files = Dir["#{d}/*"]
        files.each{|f|
          executables << File.basename(f) if FileTest.exist?(f) && File.stat(f).executable? 
        }
      end
    }
    executables
  end
  
  
  def on_wmii_event(_event)
    #log(@name,"Event=> sign:#{_event.sign}  sender:#{_event.sender}",LogLevel::TRACE)
    if @key_actions[_event.sender]
      system_or_instance_send(@key_actions[_event.sender],_event.sender)
    elsif @event_actions[_event.sign]
      system_or_instance_send(@event_actions[_event.sign],_event.raw)
#    elsif @tag_views.include?(_event.sender) && _event.sign=='LeftBarClick1'  
#      system_send(%Q{wmiir xwrite /ctl view "#{_event.sender}"}, _event.raw)
    else
      case _event.sign
        when "CreateTag"
          system_send(%Q{echo "#{@wmii_bar.exports['WMII_NORMCOLORS']}" "#{_event.sender}" | wmiir create "/lbar/#{_event.sender}"}, "CreateTag")
        when "DestroyTag"
          system_send(%Q{wmiir remove /lbar/#{_event.sender}}, "DestroyTag") #if Wmiir::element_in_path?("/lbar/",_event.sender)
        when "FocusTag"
          system_send(%Q{wmiir xwrite /lbar/#{_event.sender} "#{@wmii_bar.exports['WMII_FOCUSCOLORS']}" "#{_event.sender}"},"FocusTag") #if Wmiir::element_in_path?("/lbar/",_event.sender)
        when "UnfocusTag"
          system_send(%Q{wmiir xwrite /lbar/#{_event.sender} "#{@wmii_bar.exports['WMII_NORMCOLORS']}" "#{_event.sender}"},"UnfocusTag") #if Wmiir::element_in_path?("/lbar/",_event.sender)
        when "UrgentTag"
        when "NotUrgentTag"
  
        when "LeftBarClick1", "LeftBarDND"
          system_send(%Q{wmiir xwrite /ctl view "#{_event.sender}"}, _event.raw)
        when "Unresponsive"
        when "Notice"
      end
    end
  end
end
