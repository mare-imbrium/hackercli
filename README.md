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
To see current options:

        hackercli.rb --help


## Installation

    $ gem install hackercli

## Usage

    hackercli.rb --help

To view hacker news titles and urls

    hackercli.rb 

    hackercli.rb slashdot

Pipe to other commands (default separatar is a TAB)

    hackercli.rb | cut -f1,2 | nl | sort -n -r
    

To view only titles:

    hackercli.rb -t


To view description column also (this is normally not printed since it can be long):

    hackercli.rb -v

To view reddit ruby:

    hackercli.rb ruby 

    hackercli.rb <subreddit> 

Present the URL of some other RSS feed:

    hackercli.rb -u http://feeds.arstechnica.com/arstechnica/index

    hackercli.rb -u http://feeds.boingboing.net/boingboing/iBag

Save output to a YML file:

    hackercli.rb -y ruby.yml ruby 

Please try the `--help` option to see current feeds supported, and latest options.

NOTE: this has been tested only with Hackernews bigrss and reddit news' RSS, so I cannot gaurantee
how it will behave with others. Some tags such as item, title and link are expected to be present.

## Changes

### 0.0.2

-  Earlier the `-s` option was used to specify subforum. Now, it is not an option. subforum is passed
as an argument.

-  Save to YML. I would prefer to use this in a client program rather than use tabbed output. 
   The YML file contains descriptive field which some callers may require.
   The tabbed output does not contain description.

-  Several other RSS feeds have been checked out such as **slashdot** and **arstechnica**.
   You may pass "*ars:open-source*" or "*ars:software*" as an argument.
   Check `--help` for latest options and features.

## Upcoming

I've added a curses frontend to the generated yml files in bin named `hackman`, which depends on the
curses library `canis`. I am making it key-binding compliant with `corvus`, so one may switch from one
to the other without problems.

Should store the files in given location, read up forum list and other things from an info file.
(Perhaps share with corvusinfo).

## Testing and debugging

If you run into errors, or wish to repeatedly test out, you may save an RSS feed and supply the local file name to 
the program.

    wget https://news.ycombinator.com/bigrss
    hackercli.rb -u bigrss

## See Also:

### rubygems

https://rubygems.org/gems/hackercli

### hacker-curse

hacker-curse uses nokogiri to parse the actual Hackernews (or reddit) page, and can print on the CLI as well as 
be used as a library for another application. hacker-curse also provides a curses interface for viewing titles 
and comments, and launching the article or comments page in the GUI browser. Currently, the frontend is being 
developed. The library is ready and is on github. It contains a non-curses client named `corvus` which you should 
try.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hackercli/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please let me know if you find this useful, or write a front-end for this. I'd like to know how to make this more
useful, and include a link to your repo.
