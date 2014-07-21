# Hackercli

Uses hacker news RSS (bigrss) and reddit news RSS to print titles, article url, comments url, and any other information
provided. May be used as a filter for other commands.

This is a single file and so may be placed anywhere in the path. Also, one may include it in a project
and get the array of hashes for each article and use as per requirements.

This is NOT dependent on any other gem as it uses and parses the simple RSS feed using `String.scan` only.

The feed used for Hacker News is:

        https://news.ycombinator.com/bigrss

The feed used for Reddit News is (replace ruby with any other subreddit):

        http://www.reddit.com/r/ruby/.rss

Please click these links and check if they are working if there is any problem.

        hackercli.rb --help


## Installation

    $ gem install hackercli

## Usage

    hackercli.rb --help

To view hacker news titles and urls

    hackercli.rb 

Pipe to other commands (default separatar is a TAB)

    hackercli.rb | cut -f1,2 | nl | sort -n -r
    

To view only titles:

    hackercli.rb -t


To view description column also (this is normally not printed since it can be long):

    hackercli.rb -v

To view reddit ruby:

    hackercli.rb -s ruby

Present the URL of some other RSS feed:

    hackercli.rb -u https://someurl.com/.rss

NOTE: this has been tested only with Hackernews bigrss and reddit news' RSS, so I cannot gaurantee
how it will behave with others. Some tags such as item, title and link are expected to be present.


## Testing and debugging

If you run into errors, or wish to repeatedly test out, you may save an RSS feed and supply the local file name to 
the program.

    wget https://news.ycombinator.com/bigrss
    hackercli.rb -u bigrss

## See Also:

### hacker-curse

hacker-curse uses nokogiri to parse the actual Hackernews (or reddit) page, and can print on the CLI as well as 
be used as a library for another application. hacker-curse also provides a curses interface for viewing titles 
and comments, and launching the article or comments page in the GUI browser.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hackercli/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
