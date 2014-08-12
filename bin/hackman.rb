#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: hackman.rb
#  Description: curses frontend for rss feeds generated by hackercli
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-08-09 - 10:12
#      License: MIT
#  Last update: 2014-08-12 17:38
# ----------------------------------------------------------------------------- #
#  hackman.rb  Copyright (C) 2012-2014 j kepler
# encoding: utf-8
require 'canis/core/util/app'
require 'canis/core/util/rcommandwindow'
require 'fileutils'
require 'pathname'
require 'canis/core/include/defaultfilerenderer'
require 'canis/core/include/appmethods'

# TODO : 
#    x add to forum list, remove, save
#    - specify gui browser and text browser, and on commandline use same keys as corvus
#    - create a class and put stuff in there, these methods are going into global, and can conflict
#    - we should have same mechanism for key bindings as corvus, something that can even be loaded?
#    
#    - Use ' as bookmark etc just as in cetus and corvus, keep to same keys
#    - multibuffers so user can backspace and do M-n etc
#    
VERSION="0.0.2"
COLOR_SCHEMES=[ 
  [20,19,17, 18, :white], # 0 band in header, 1 - menu bgcolor.  2 - bgcolor of main screen, 3 - status, 4 fg color body
  [17,19,18, 20, :white], # 0 band in header, 1 - menu bgcolor.  2 - bgcolor of main screen, 3 - status
  [236,236,0, 232,:white], # 0 band in header, 1 - menu bgcolor.  2 - bgcolor of main screen, 3 - status
  [236,236,244, 234, :black] # 0 band in header, 1 - menu bgcolor.  2 - bgcolor of main screen, 3 - status
]
$color_scheme = COLOR_SCHEMES[0]
$toggle_titles_only = false
$fg = :white
$forumlist = %w{ hacker ruby programming scifi science haskell java scala cpp c_programming d_language golang vim emacs unix linux bash zsh commandline vimplugins python ars slashdot }
def choose_forum
  # scrollable filterable list
  str = display_list $forumlist, :title => "Select a forum"
  return unless str
  return if str == ""
  $current_forum = str
  forum = str
  get_data forum if forum
end
# add a forum at runtime, by default this will be a reddit subforum
def add_forum forum=nil
  unless forum
    forum = get_string "Add a reddit subforum: "
    return if forum.nil? or forum == ""
  end
  $forumlist << forum
  get_data forum
end
def remove_forum forum=nil
  unless forum
    forum = display_list $forumlist, :title => "Select a forum"
    return if forum.nil? or forum == ""
  end
  $forumlist.delete forum
end
def next_forum
  index = $forumlist.index($current_forum)
  index = index >= $forumlist.count - 1 ? 0 : index + 1
  get_data $forumlist[index]
end
def prev_forum
  index = $forumlist.index($current_forum)
  index = index == 0? $forumlist.count - 1 : index - 1
  get_data $forumlist[index]
end
# if components have some commands, can we find a way of passing the command to them
# method_missing gave a stack overflow.
def execute_this(meth, *args)
  alert " #{meth} not found ! "
  $log.debug "app email got #{meth}  " if $log.debug? 
  cc = @form.get_current_field
  [cc].each do |c|  
    if c.respond_to?(meth, true)
      c.send(meth, *args)
      return true
    end
  end
  false
end
def open_url url
  shell_out "elinks #{url}"
  #Window.refresh_all
end

  ## 
  # Menu creator which displays a menu and executes methods based on keys.
  # In some cases, we call this and then do a case statement on either key or binding.
  # @param String title
  # @param hash of keys and methods to call
  # @return key pressed, and binding (if found, and responded)
  #
  def menu title, hash, config={}, &block
    raise ArgumentError, "Nil hash received by menu" unless hash
    list = []
    hash.each_pair { |k, v| list << "   #[fg=yellow, bold] #{k} #[/end]    #[fg=green] #{v} #[/end]" }
    #  s="#[fg=green]hello there#[fg=yellow, bg=black, dim]"
    config[:title] = title
    config[:width] = hash.values.max_by(&:length).length + 13
    ch = padpopup list, config, &block
    return unless ch
    if ch.size > 1
      # could be a string due to pressing enter
      # but what if we format into multiple columns
      ch = ch.strip[0]
    end

    binding = hash[ch]
    binding = hash[ch.to_sym] unless binding
    if binding
      if respond_to?(binding, true)
        send(binding)
      end
    end
    return ch, binding
  end
  # pops up a list, taking a single key and returning if it is in range of 33 and 126
  # Called by menu, print_help, show_marks etc
  # You may pass valid chars or ints so it only returns on pressing those.
  #
  # @param Array of lines to print which may be formatted using :tmux format
  # @return character pressed (ch.chr)
  # @return nil if escape or C-q pressed
  #
  def padpopup list, config={}, &block
    max_visible_items = config[:max_visible_items]
    row = config[:row] || 5
    col = config[:col] || 5
    # format options are :ansi :tmux :none
    fmt = config[:format] || :tmux
    config.delete :format
    relative_to = config[:relative_to]
    if relative_to
      layout = relative_to.form.window.layout
      row += layout[:top]
      col += layout[:left]
    end
    config.delete :relative_to
    # still has the formatting in the string so length is wrong.
    #longest = list.max_by(&:length)
    width = config[:width] || 60
    if config[:title]
      width = config[:title].size + 2 if width < config[:title].size
    end
    height = config[:height]
    height ||= [max_visible_items || 25, list.length+2].min 
    #layout(1+height, width+4, row, col) 
    layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
    window = Canis::Window.new(layout)
    form = Canis::Form.new window

    ## added 2013-03-13 - 18:07 so caller can be more specific on what is to be returned
    valid_keys_int = config.delete :valid_keys_int
    valid_keys_char = config.delete :valid_keys_char

    listconfig = config[:listconfig] || {}
    #listconfig[:list] = list
    listconfig[:width] = width
    listconfig[:height] = height
    listconfig[:bgcolor] = $color_scheme[1]
    #listconfig[:selection_mode] ||= :single
    listconfig.merge!(config)
    listconfig.delete(:row); 
    listconfig.delete(:col); 
    # trying to pass populists block to listbox
    lb = Canis::TextPad.new form, listconfig, &block
    if fmt == :none
      lb.text(list)
    else
      lb.text(list, fmt)
    end
    #
    #window.bkgd(Ncurses.COLOR_PAIR($reversecolor));
    form.repaint
    Ncurses::Panel.update_panels
    if valid_keys_int.nil? && valid_keys_char.nil?
      # changed 32 to 33 so space can scroll list
      valid_keys_int = (33..126)
    end

    begin
      while((ch = window.getchar()) != 999 )

        # if a char range or array has been sent, check if the key is in it and send back
        # else just stay here
        if valid_keys_char
          if ch > 32 && ch < 127
            chr = ch.chr
            return chr if valid_keys_char.include? chr
          end
        end

        # if the user specified an array or range of ints check against that
        # therwise use the range of 33 .. 126
        return ch.chr if valid_keys_int.include? ch

        case ch
        when ?\C-q.getbyte(0)
          break
        else
          if ch == 13 || ch == 10
            s = lb.current_value.to_s # .strip #if lb.selection_mode != :multiple
            return s
          end
          # close if escape or double escape
          if ch == 27 || ch == 2727
            return nil
          end
          lb.handle_key ch
          form.repaint
        end
      end
    ensure
      window.destroy  
    end
    return nil
  end
  # main options, invokable on backtick.
  # TODO add selection of browser
def main_menu
  h = { 
    :f => :choose_forum,
    :c => :color_scheme_select,
    :s => :sort_menu, 
    :F => :filter_menu,
    :a => :add_forum,
    :d => :remove_forum,
    :x => :extras
  }
  ch, binding = menu "Main Menu", h
  #alert "Menu got #{ch}, #{binding}" if ch
end
def toggle_menu
  h = { 
    "t" => :toggle_titles_only,
    :x => :extras
  }
  ch, binding = menu "Main Menu", h
  #alert "Menu got #{ch}, #{binding}" if ch
end
def color_scheme_select ch=nil
  unless ch
    h = { 
      "0" => 'dark blue body',
      "1" => 'medium blue body',
      "2" => 'black body',
      "3" => 'grey body',
      "b" => 'change body color',
      "f" => 'change body fg color',
      "c" => 'cycle body color'
    }
    ch, binding = menu "Color Menu", h
  end
  case ch
  when "1", "2", "0", "3"
    $color_scheme = COLOR_SCHEMES[ch.to_i] || COLOR_SCHEMES.first
    $fg = $color_scheme[4]
  when "b"
    n = get_string "Enter a number for background color (0..255): "
    n = n.to_i
    $color_scheme[2] = n
  when "4", "f"
    n = get_string "Enter a number for fg color (0..255) : "
    $fg = n.to_i
  when "c"
    # increment bg color
    n = $color_scheme[2]
    n += 1
    n = 0 if n > 255
    $color_scheme[2] = n
  when "C"
    # decrement bg color
    n = $color_scheme[2]
    n -= 1
    n = 255 if n < 0
    $color_scheme[2] = n
  end

  h = @form.by_name["header"]
  tv = @form.by_name["tv"]
  sl = @form.by_name["sl"]
  tv.bgcolor = $color_scheme[2]
  #tv.color = 255
  tv.color = $fg
  sl.color = $color_scheme[3]
  h.bgcolor = $color_scheme[0]
  message "bgcolor is #{$color_scheme[2]}. :: #{$color_scheme.join(",")}, CP:#{tv.color_pair}=#{tv.color} / #{tv.bgcolor} "
  refresh
end
def refresh
  show $current_file
end

def toggle_titles_only
  $toggle_titles_only = !$toggle_titles_only
  show $current_file
end
App.new do 
  @startdir ||= File.expand_path("..")
  @hash = nil
  def get_item_for_line line
    index = (line - @hash[:first]) / @hash[:diff]
    @hash[:articles][index]
  end
  def title_right text
    w = @form.by_name["header"]
    w.text_right text
  end
  def title text
    w = @form.by_name["header"]
    w.text_center text
  end
  def color_line(fg,bg,attr,text)
    a = "#["
    a = []
    a << "fg=#{fg}" if fg
    a << "bg=#{bg}" if bg
    a << "#{attr}" if attr
    str = "#[" + a.join(",") + "]#{text}#[end]"
  end
  def goto_article n=$multiplier
    i = ((n-1) * @hash[:diff]) +  @hash[:first] 
    w = @form.by_name["tv"]
    w.goto_line i
  end

  def OLDshow file
    w = @form.by_name["tv"]
    if File.directory? file
      lines = Dir.entries(file)
      w.text lines
      w.title "[ #{file} ]"
    elsif File.exists? file
      lines = File.open(file,'r').readlines 
      w.text lines
      w.title "[ #{file} ]"
    end
  end
  # display the given yml file. 
  # Converts the yml object to an array for textpad
  def display_yml file
    w = @form.by_name["tv"]

    obj = YAML::load( File.open( file ) )
    lines = Array.new
    url = obj[:page_url]
    host = nil
    if url.index("reddit")
      host = "reddit"
    elsif url.index("ycombinator")
      host = "hacker"
    elsif url.index("ars")
      host = "ars"
    elsif url.index("slashdot")
      host = "slashdot"
    else
      alert "Host not known: #{url} "
    end
    articles = obj[:articles]
    count = articles.count
    #lines << color_line(:red,COLOR_SCHEME[1],nil,"#{file}  #{obj[:page_url]}  |  #{count} articles | fetched  #{obj[:create_time]}")
    #lines << ("-" * lines.last.size )
    @hash = Hash.new
    @hash[:first] = lines.size
    @hash[:articles] = articles

    articles.each_with_index do |a, i|
      bg = i
      bg = 0 if i > 255
      line = "%3s  %s  " % [i+1 , a[:title] ]
      #lines << color_line($fg, bg, nil, line)
      lines << line
      if !$toggle_titles_only
        url = a[:article_url] || a[:url]
        l = "        %s | %s" % [url, a[:comments_url] ]
        l = "#[fg=green, underline]" + l + "#[end]"
        lines << l
        detail = []
        if a.key? :comment_count
          detail << a[:comment_count]
        end
        if a.key? :pubdate
          detail << a[:pubdate]
        end
        unless detail.empty?
          l =  "#[fg=green]" + "         " + detail.join(" | ") + "#[end]"
          lines << l
        end
      end
      @hash[:diff] ||= lines.size - @hash[:first]
    end
    w.text(lines, :content_type =>  :tmux)
    w.title "[ #{file} ]"

    i = @hash[:first] || 1
    w.goto_line i
    $current_file = file
    $current_forum = file.sub(File.extname(file),"")
    title "#{$current_forum} (#{count} articles) "
    title_right obj[:create_time]
  end
  alias :show :display_yml
  def get_data forum
    file = forum + ".yml"
    if File.exists? file and fresh(file)
    else
      progress_dialog :color_pair => $reversecolor do |sw|
        #sw.printstring 0,1, "Fetching #{forum} ..."
        sw.print "Fetching #{forum} ..."
        system("hackercli.rb -y #{forum}.yml #{forum}")
      end
    end
    display_yml file
  end
  # return true if younger than one hour
  def fresh file
    f = File.stat(file)
    now = Time.now
    return (( now - f.mtime) < 7200)
  end
  def show_links art
      links = {}
      keys = %w{a b c d e f}
      i = 0
      art.each_pair do |k, p|
        if p.index("http") == 0
          links[keys[i]] = p
          i += 1
        end
      end
      ch, binding = menu "Links Menu", links
      #alert "is #{index}: #{art[:title]} #{ch}:#{binding} "
      if binding
        open_url binding
      end
  end
  ht = 24
  borderattrib = :reverse
  @header = app_header "hackman #{VERSION}", :text_center => "RSS Reader", :name => "header",
    :text_right =>"Press =", :color => :white, :bgcolor => $color_scheme[0]
  message "Press F10 (or qq) to exit, F1 Help, ` for Menu  "


    
    # commands that can be mapped to or executed using M-x
    # however, commands of components aren't yet accessible.
    def get_commands
      %w{ choose_forum next_forum prev_forum }
    end
    def help_text
      <<-eos
               rCommandLine HELP 

      These are some features for either getting filenames from user
      at the bottom of the window like vim and others do, or filtering
      from a list (like ControlP plugin). Or seeing a file at bottom
      of screen for a quick preview.

      :        -   Command mode
      F1       -   Help
      F10      -   Quit application
      qq       -   Quit application
      =        -   file selection (interface like Ctrl-P, very minimal)

      Some commands for using bottom of screen as vim and emacs do.
      These may be selected by pressing ':'

      testchoosedir       - filter directory list as you type
                            '>' to step into a dir, '<' to go up.
      testchoosefile       - filter file list as you type
                             ENTER to select, C-c or Esc-Esc to quit
      testdir          - vim style, tabbing completes matching files
      testnumberedmenu - use menu indexes to select options
      choose_forum  - display a list at bottom of screen
                         Press <ENTER> to select, arrow keys to traverse, 
                         and characters to filter list.
      testdisplaytext  - display text at bottom (current file contents)
                         Press <ENTER> when done.

      The file/dir selection options are very minimally functional. Improvements
      and thorough testing are required. I've only tested them out gingerly.

      testchoosedir and file were earlier like Emacs/memacs with TAB completion
      but have now moved to the much faster and friendlier ControlP plugin like
      'filter as you type' format.

      -----------------------------------------------------------------------
      :n or Alt-n for general help.
      eos
    end

    #install_help_text help_text

    def app_menu
      @curdir ||= Dir.pwd
      Dir.chdir(@curdir) if Dir.pwd != @curdir
      require 'canis/core/util/promptmenu'
      menu = PromptMenu.new self do
        item :f, :choose_forum
        item :t, :testdisplay_text
      end
      menu.display_new :title => "Menu"
    end
    # BINDING SECTION
  @form.bind_key(?:, "App Menu") { app_menu; }
  @form.bind_key(?`, "Main Menu") { main_menu; }
  @form.bind_key(FFI::NCurses::KEY_F2, "Main Menu") { choose_forum; }
  @form.bind_key(FFI::NCurses::KEY_F3, "Cycle bgcolor") { color_scheme_select "c"; }
  @form.bind_key(FFI::NCurses::KEY_F4, "Cycle bgcolor") { color_scheme_select "C"; }
  @form.bind_key($kh_int["S-F3"], "Cycle bgcolor") { color_scheme_select "C"; }
  @form.bind_key(?=, "Toggle Menu") { 
    toggle_menu; 
  }
  @form.bind_key(?<, "Previous Forum") { prev_forum; }
  @form.bind_key(?>, "Next Forum") { next_forum; }

  stack :margin_top => 1, :margin_left => 0, :width => :expand , :height => FFI::NCurses.LINES-2 do
    tv = textpad :height_pc => 100, :width_pc => 100, :name => "tv", :suppress_borders => true,
      :bgcolor => $color_scheme[2], :color => 255, :attr => NORMAL
    #tv.renderer ruby_renderer
    tv.bind(:PRESS) {|ev|
      index = ev.current_index
      art = get_item_for_line index
      show_links art
    }
    tv.bind_key(?z) { goto_article }
    tv.bind_key(?o) { 
      # if multiplier is 0, use current line
      art =  @hash[:articles][$multiplier - 1]
      if $multiplier == 0
        index = tv.current_index
        art = get_item_for_line index
      end
      show_links art
      }
    tv.text_patterns[:articles] = Regexp.new(/^ *\d+ /)
    tv.bind_key(KEY_TAB, "goto article") { tv.next_regex(:articles) }
  end # stack
    
  sl = status_line :row => Ncurses.LINES-1, :bgcolor => :yellow, :color => $color_scheme[3]
  choose_forum 
end # app
