# GrepSocial

Tool to periodically query social websites (YouTube, Instagram, Twitter, Flickr, etc), and get items posted by people.

It's great for yall camwhores who've just back from some public event and want to find all the pics of yourself.
You know who you are.

It has 2 scripts:
* `grepsocial.rb` to be run every few hours. Will query websites and save data.
* `index.rb` will display a page with all the current 'unseen' results. Just refresh the page until you've seen all the posts.

It currently checks:
* YouTube (needs API key)
* Twitter (needs API key)
* Flickr
* Instagram

## Install

    apt install ruby-nokogiri
    git clone https://github.com/furikuda/grepsocial

## Config

To enable sites to grep for, copy or link them from sites-available to sites-enabled.

Just read the output of `ruby grepsocial.rb -h`

### YouTube

The youtube.rb plugin requires an API key. Save it in a file called `.ytapikey`.

### Twitter

The twitter.rb plugin requires an API key. Save it in a file called `.twitterapikey`.

## Run

Edit index.rb to change login & password to your linkings. Or remove that part entirely:

    use Rack::Auth::Basic, "Restricted Area" do |username, password|
          username == 'admin' and password == 'pwd'
    end

Add this to your crontab:

    0   */6 *   *   * cd /var/www/grepsocial/ ; ruby grepsocial.rb

Run the website standalone:

    ruby index.rb

Then point your browser to http://localhost:4567/

Or run it on some httpd. For Apache2, you'll need the package `libapache2-mod-passenger`.

To get a list of all the new posts, go to /new. Default creds are `admin`/`admin`, but you can change them:

    echo -n "login:passw0rd" > .htpasswd


## CONTRIBUTING


