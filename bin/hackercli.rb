#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: hackercli.rb 
#  Description: reads Hacker News bigrss feed and prints out
#               Also works with reddit's rss feed 
#
#               This is just a quick dirty printer mainly meant for printing 
#               titles and connecting to the page. HN's rss does not provide any info
#               such as points/age etc. Reddit provides a little more but has to be parsed.
#
#               Currently saves downloaded file as "<forum>.rss" so you may rerun queries on it
#               using the "-u" flag.
#
#               Caveats: fails if newlines in rss feed as in case of arstechnical
#               We need to join the lines first so that scan can work
#
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-20 - 11:37
#      License: MIT
#  Last update: 2014-07-21 17:50
# ----------------------------------------------------------------------------- #
#  hackercli.rb  Copyright (C) 2012-2014 j kepler

require 'nokogiri'
require 'open-uri'
require 'cgi'

class Bigrss
  # mainly options receives a url 
  # Also a file name can be sent especially if testing a program and you dont
  # want to hit the site too often.
  def initialize options={}, &block
    @options = options
    #@arg = arg
    #instance_eval &block if block_given?
  end

  # # returns a hash containing :articles array, and one or two outer fields such as page_url and time
  # returns an array containing a hash for each article
  # The hash contains :title, :url, :comments_url and in some case :pubdata and comments_count
  def run
    page = {}

    resp = []
    filename = @options[:url]
    ymlpath = @options[:ymlpath]
    page[:page_url] = filename
    now = Time.now
    page[:create_time_seconds] = now.to_i
    page[:create_time] = now.to_s
    page[:articles] = resp
    f = open(filename)
    outfile = @options[:subreddit] || "last"
    # ars technical sends in new lines
    content = f.read.delete("\n")
    content.gsub!('&#x2F;',"/")
    content.gsub!('&#x27;',"'")
    content.gsub!('&#x34;','"')
    content = CGI.unescapeHTML(content)
    # next line dirties current dir, does not respect path of yml
    outfile = File.join(ymlpath, outfile) if ymlpath
    File.open("#{outfile}.rss","w") {|ff| ff.write(content) }
    cont = Nokogiri::XML(content)
    items = cont.css("item")
    if items.empty? 
      items = cont.css("entry")
    end
    raise ArgumentError, "Cannot locate item or entry in RSS feed" if items.empty?

    items.each do |e|
      h = {}
      e.children.each do |c|
        # if the text is nil (as in reddit for link and category, then try to get attribute
        if c.text.nil? or c.text == ""
          #h[c.name] = []
          #c.attributes.each { |a|
          #h[c.name] << c[a.first]
          #}

          x = c.attributes.first.first
          h[c.name.downcase.to_sym] = c[x]
          #h[c.name] = "XXXXX"
        else
          h[c.name.downcase.to_sym] = c.text
        end
      end
      if h.key? :updated
        h[:pubdate] = h.delete(:updated)
      end
      resp << h
    end

    return page unless block_given?
  end
  def extract_part e, tag, hash
    if e.index("<#{tag}>")
      str = e.scan(/<#{tag}>(.*?)<\/#{tag}/).first.first
      hash[tag.to_sym] = str
      return str
    end
    return nil
  end

  # more for the reddit rss which requires the description to be parsed for comments, article link 
  def split_description s, h
    str = s.scan(/<a href="(.*?)">(.*?)<\/a>/)
    if str
      str.each do |e|
        if e[1] == "[link]"
          h[:article_url] = e.first
        elsif e[1].index("comment")
          h[:comment_count] = e[1]
          h[:comments_url] = e.first
        end
      end
    end
  end

end



def to_yml outfile, arr
  require 'yaml'
  File.open(outfile, 'w' ) do |f|
    f << YAML::dump(arr)
  end
end




#if __FILE__ == $0
if true
  begin
    url = nil
    ymlfile = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    appname = File.basename $0
    OptionParser.new do |opts|
      opts.banner = 
        %Q{ 
Usage: #{$0} [options]
 Examples:
  Display Hacker News titles and urls:
    #{appname} 
    #{appname} hacker
  Display subreddits from reddit.com:
    #{appname} programming
    #{appname} ruby
  Display info from other sites:
    #{appname} ars                # index from arstechnica
    #{appname} ars:software       # software from arstechnica
    #{appname} ars:open-source    # open-source from arstechnica
    #{appname} slashdot   
  Display info from a saved rss file:
    #{appname} -u ruby.rss
  Save info from reddit ruby to a YML file:
    #{appname} -y ruby.yml ruby
  Display info from another url: 
    #{appname} -u http://feeds.boingboing.net/boingboing/iBag
    #{appname} -u http://www.lifehacker.co.in/rss_tag_section_feeds.cms?query=productivity
    #{appname} -u http://rss.slashdot.org/Slashdot/slashdot
    #{appname} -u http://feeds.arstechnica.com/arstechnica/open-source
    #{appname} -u http://feeds.arstechnica.com/arstechnica/software
    

}

      opts.on("-v", "--[no-]verbose", "Print description also") do |v|
        options[:verbose] = v
      end
      opts.on("-n N", "--limit", Integer, "limit to N stories") do |v|
        options[:number] = v
      end
      opts.on("-t", "print only titles") do |v|
        options[:titles] = true
      end
      opts.on("-d SEP", String,"--delimiter", "Delimit columns with SEP") do |v|
        options[:delimiter] = v
      end
      opts.on("-y yml path", String,"--yml-path", "save as YML file") do |v|
        ymlfile = v
        options[:ymlpath] = File.dirname(v)
      end
      #opts.on("-s SUBREDDIT", String,"--subreddit", "Get articles from subreddit named SUBREDDIT") do |v|
        #options[:subreddit] = v
        #url = "http://www.reddit.com/r/#{v}/.rss"
      #end
      opts.on("-u URL", String,"--url", "Get articles from URL/file") do |v|
        url = v
      end
    end.parse!

    #p options
    #p ARGV

    v = ARGV[0];
    if v
      case v
      when "news", "hacker", "hn"
        url = "https://news.ycombinator.com/bigrss"
        options[:subreddit] = "hacker"
      when "slashdot"
        url = "http://rss.slashdot.org/Slashdot/slashdot"
        options[:subreddit] = "slashdot"
      when "ars"
        url = "http://feeds.arstechnica.com/arstechnica/index"
        options[:subreddit] = "arstechnica"
      else
        if v.index("ars:") == 0
          subf = v.split(":")
          url = "http://feeds.arstechnica.com/arstechnica/#{subf.last}"
          options[:subreddit] = subf.join("_")
        else
          url = "http://www.reddit.com/r/#{v}/.rss" 
          options[:subreddit] = v
        end
      end
    end
    unless url
      url ||= "https://news.ycombinator.com/bigrss"
      options[:subreddit] = "hacker"
    end
    #$stderr.puts "url is: #{url} "

    options[:url] = url
    klass = Bigrss.new options
    page = klass.run
    if ymlfile
      to_yml ymlfile, page
      exit
    end
    arr = page[:articles]
    titles_only = options[:titles]
    sep = options[:delimiter] || "\t"
    limit = options[:number] || arr.count
    arr.each_with_index do |e, i|
      break if i >= limit
      if titles_only
        puts "#{e[:title]}"
      else
        unless options[:verbose]
          e.delete(:description)
        end
        if i == 0
          s = e.keys.join(sep)
          puts s
        end
        s = e.values.join(sep)
        puts s
        #puts "#{e[:title]}#{sep}#{e[:url]}#{sep}#{e[:comments_url]}"
      end
    end
    #puts " testing block "
    #klass.run do | t,u,c|
      #puts t
    #end
  ensure
  end
end

