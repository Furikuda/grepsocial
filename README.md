# GrepSocial

Tool to periodically query social websites (YouTube, Instagram, Twitter, etc), and get items posted by people.

It's great for yall camwhores who've just back from some public event and want to find all the pics of your self.
You know who you are.

It has 2 scripts:
* `grepsocial.rb` to be run every few hours. Will query websites and save data.
* `index.rb` will display a page with all the current 'unseen' results. Just refresh the page until you've seen all the posts.

It currently checks:
* YouTube (needs API key)
* Twitter (needs API key)
* Flickr
* Instagram

## INSTALL

    cd public/
    wget https://github.com/twbs/bootstrap/releases/download/v3.3.6/bootstrap-3.3.6-dist.zip
    unzip bootstrap-3.3.6-dist.zip
    mv bootstrap-3.3.6-dist/css/bootstrap.min.css css/
    mv bootstrap-3.3.6-dist/js/bootstrap.min.js js/
    rm -rf bootstrap*
    cd js
    wget https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js
    cd ../../lib
    git clone https://github.com/jjyg/libhttpclient.git
    apt-get install ruby-twitter

## Config

Every interesting configuration stanza will be in `config.rb`.

### YouTube

The youtube.rb plugin requires an API key.

Either save youtube API key in a file called `.ytapikey`, or disable the Youtube plugin, in config.rb :

    :sites_disabled => ["youtube.rb"]

### Twitter

The twitter.rb plugin requires an API key.

Either save youtube API key in a file called `.twitterapikey`, or disable the Twitter plugin, in config.rb :

    :sites_disabled => ["twitter.rb"]

## Run

Add this to your crontab:

    0   */6 *   *   * cd /var/www/grepsocial/ ; ruby grepsocial.rb

Run the website standalone:

    ruby index.rb

Then point your browser to http://localhost:4567/

Or run it on some httpd. For Apache2, you'll need the package `libapache2-mod-passenger`.

To get a list of all the new posts, go to /new. Default creds are `admin`/`admin`, but you can change them:

    echo -n "login:passw0rd" > .htpasswd


If you tick a box, it tells the backend to "keep" this post.

The root page `/` will show you all the kept posts.



## CONTRIBUTING

### Add a new site

Just copy `sites/_template.rb` and tweak it to your needs.


