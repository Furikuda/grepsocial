require_relative "../site.rb"

class TwitterSite < SocialSite
  require "twitter"

  class TwitterError < Exception
  end

  attr_accessor :twitter
  def initialize()
    super()
    @twitter = nil
  end
  def load_creds(path:nil)
      path = get_api_file_path(path:path)
      json_content = nil
      File.open(path, 'r') do |f|
          json_content = f.read().strip()
      end
      @creds = JSON.parse(json_content)
  end

  def get_api_file_path(path:nil)
      res = path
      unless res
          res = File.join(File.dirname(File.basename(__FILE__)), ".twitterapikey")
      end
      unless File.exist?(res)
          raise TwitterError.new("No Twitter api file ('#{File.absolute_path(res)}'), Twitter might not work properly")
      end
      return res
  end

  def connect
    load_creds()
    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = @creds['api_key']
      config.consumer_secret     = @creds['api_secret_key']
      config.access_token        = @creds['access_token']
      config.access_token_secret = @creds['access_token_secret']
    end
  end

  def fetch_new(max_results: 200)
      # Because we need to be careful of rate limiting
      new_items = []
      max_per_tag = max_results/( @tags.size + 1 )
      @tags.each do |tag|
          debug "Searching for #{tag}"
          new_items.concat(fetch_new_tag(tag, max_results: max_per_tag))
      end
      return new_items
  end

  def extract_si(tweet)
    sis = []
    if tweet.quoted_status?
      quoted_tweet = @twitter.statuses(tweet.quoted_tweet.id, tweet_mode:'extended')[0]
      return extract_si(quoted_tweet)
    end
    if tweet.media?
      tweet.media.each do |m|
        si = SocialSite::Item.new()
        si.site = "Twitter"
        si.date = Time.now.to_i
        si.url = tweet.url.to_s
        si.source = tweet.url.to_s
        si.type = m.type
        si.thumb = m.media_uri.to_s
        if m.type == "photo"
          si.identifier = m.media_uri.to_s
        elsif m.type == "video" or m.type == "animated_gif"
          vi = m.video_info
          video_url = vi.attrs[:variants].select{|var| var[:content_type].start_with?('video/')}.sort_by{|var| var[:bitrate]}[0][:url]
          si.identifier = video_url
        else
          raise Exception.new("unsupported type in #{tweet.url} : #{tweet.type}")
        end
        sis << si
      end
    end
    if tweet.urls?
      tweet.urls.each do |turl|
        si = SocialSite::Item.new()
        si.site = "Twitter"
        si.date = Time.now.to_i
        si.url = tweet.url.to_s
        si.source = tweet.url.to_s
        si.type = "link"
        si.identifier = turl.expanded_url.to_s
        sis << si
      end
    end
    return sis
  end

  def fetch_new_tag(tag, max_results:100)
    items = []
    connect if not @twitter
    begin
      results = @twitter.search(tag, result_type: "recent", count:max_results, tweet_mode:'extended')
    rescue Twitter::Error::TooManyRequests
      return []
    end
    results.each do |t|
      next if t.retweet?
      items.concat(extract_si(t))
    end
    return items
  end
end

if __FILE__ == $0
  t = TwitterSite.new()
  t.connect
 # tweet = t.twitter.statuses("1458903961054896134")[0]
  pp t.fetch_new_tag("test")
#  pp tweet.to_h
#  binding.pry
  pp t.extract_si(tweet)
end

