require_relative "../site.rb"

class TwitterSite < SocialSite
  require "twitter"

  class TwitterError < Exception
  end

  attr_accessor :twitter
  def initialize()
    super()
    @name = "twitter"
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

  def fetch_new(max_results: 450)
      # Because we need to be careful of rate limiting
      new_items = []
      max_per_tag = max_results/( @tags.size + 1 )
      @tags.each do |tag|
          debug "Searching for #{tag}"
          begin
          new_items.concat(fetch_new_tag(tag, max_results: max_per_tag))
          rescue Twitter::Error::TooManyRequests
          end
      end
      return new_items
  end

  def fetch_new_tag(tag, max_results:80)
    items = []
    connect if not @twitter
    results = @twitter.search(tag, result_type: "recent", count:max_results, tweet_mode:'extended')
    results.each do |t|
      next if t.retweet?
      if t.media?
        t.media.each do |m|
          si = SocialSite::Item.new()
          si.site = "Twitter"
          si.date = Time.now.to_i
          si.url = t.url.to_s
          si.source = t.url.to_s
          si.type = m.type
          if m.type == "photo"
            si.identifier = m.media_uri.to_s
            si.thumb = m.media_uri.to_s
          elsif m.type == "video"
            si.thumb = m.media_uri.to_s
            vi = m.video_info
            video_url = vi.attrs[:variants].select{|var| var[:content_type].start_with?('video/')}.sort_by{|var| var[:bitrate]}[0][:url]
            si.identifier = video_url
          elsif m.type == "animated_gif"
            si.thumb = m.media_uri.to_s
            vi = m.video_info
            video_url = vi.attrs[:variants].select{|var| var[:content_type].start_with?('video/')}.sort_by{|var| var[:bitrate]}[0][:url]
            si.identifier = video_url
          else
            raise Exception.new("unsupported type #{m.type} for #{t.url}")
          end
          items << si
        end
      end
      if t.urls?
        t.urls.each do |turl|
          si = SocialSite::Item.new()
          si.site = "Twitter"
          si.date = Time.now.to_i
          si.url = t.url.to_s
          si.source = t.url.to_s
          si.type = "link"
          si.identifier = turl.expanded_url.to_s
          items << si
        end
      end
    end
    return items
  end
end

if __FILE__ == $0
  t = TwitterSite.new()
  t.connect
  res = t.fetch_new_tag('test')
  res.each do |s|
    pp s
  end
end
