#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: bigrss.rb
#  Description: reads Hacker News bigrss feed and prints out
#               Also works with reddit's rss feed 
#
#               This is just a quick dirty printer mainly meant for printing 
#               titles and connecting to the page. HN's rss does not provide any info
#               such as points/age etc. Reddit provides a little more but has to be parsed.
#
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-20 - 11:37
#      License: MIT
#  Last update: 2014-07-20 20:37
# ----------------------------------------------------------------------------- #
#  bigrss.rb  Copyright (C) 2012-2014 j kepler

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

  def run
    resp = []
    filename = @options[:url]
    f = open(filename)
    content = f.read
    content.gsub!('&#x2F;',"/")
    content.gsub!('&#x27;',"'")
    content.gsub!('&#x34;','"')
    content = CGI.unescapeHTML(content)
    File.open("t.rss","w") {|ff| ff.write(content) }
    items = content.scan(/<item>(.*?)<\/item>/)
    items.each_with_index do |e,i|
      e = e.first
      h = {}
      title = e.scan(/<title>(.*?)<\/title/).first.first
      h[:title] = title
      url = e.scan(/<link>(.*?)<\/link/).first.first
      h[:url] = url
      comment_url = ""
      # HN has comments links in a  tag
      c = e.scan(/<comments>(.*?)<\/comments/).first
      comment_url = c.first if c
      h[:comments_url] = comment_url
      # reddit gives published date
      if e.index("pubDate")
        pubdate = e.scan(/<pubDate>(.*?)<\/pubDate/).first.first
        h[:pubdate] = pubdate
      end
      # reddit rss does not have comments. link comes embedded inside description
      s = extract_part e, "description", h
      if s 
        # for reddit
        split_description s, h
      end
      if block_given?
        yield title, url, comment_url
      else
        #resp << [title, url, comment_url]
        resp << h
      end
      #puts " #{title}#{sep}#{url}#{sep}#{comment_url}"
    end
    return resp unless block_given?
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







if __FILE__ == $0
  begin
    url = nil
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
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
      opts.on("-s SUBREDDIT", String,"--subreddit", "Get articles from subreddit named SUBREDDIT") do |v|
        options[:subreddit] = v
        url = "http://www.reddit.com/r/#{v}/.rss"
      end
      opts.on("-u URL", String,"--url", "Get articles from URL") do |v|
        url = v
      end
    end.parse!

    #p options
    #p ARGV

    #filename=ARGV[0];
    url ||= "https://news.ycombinator.com/bigrss"
    puts url
    options[:url] = url
    klass = Bigrss.new options
    arr = klass.run
    titles_only = options[:titles]
    sep = options[:delimiter] || "\t"
    limit = options[:number] || arr.count
    arr.each_with_index do |e, i|
      break if i >= limit
      if titles_only
        puts "#{e[:title]}"
      else
        #puts "#{e[:title]}#{sep}#{e[:url]}#{sep}#{e[:comments_url]}"
        puts e.keys, e.values
        puts
      end
    end
    #puts " testing block "
    #klass.run do | t,u,c|
      #puts t
    #end
  ensure
  end
end

