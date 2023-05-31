require_relative "../site.rb"

class NitterSite < SocialSite
  require "net/http"
  require "nokogiri"

  class NitterError < Exception
  end

  attr_accessor :nitter
  def initialize(nitter_instance:"")
    super()
    @name = "nitter"
    raise NitterError.new('cannot have an empty nitter instance') if nitter_instance == ""
    @nitter_instance = URI.parse(nitter_instance)
  end

  def instance_base_url()
    return "#{@nitter_instance.scheme}://#{@nitter_instance.hostname}:#{@nitter_instance.port}"
  end

  def fetch_new(max_results: 450)
      # Because we need to be careful of rate limiting
      new_items = []
      max_per_tag = max_results/( @tags.size + 1 )
      @tags.each do |tag|
          debug "Searching for #{tag}"
          new_items.concat(fetch_new_tag(tag, max_results: max_per_tag))
      end
      return new_items
  end

  def parse_one_tweet(tweet)
    items = []
    interesting_links = tweet.css("div.tweet-content a").map {|a| a['href'].start_with?('http') ? a['href'] : nil}.compact
    atts = tweet.css("div.attachments")
    cards = tweet.css("div.card")

    tweet_url = "https://twitter.com"+ tweet.css("span.tweet-date a")[0]['href']
    return [] if tweet_url=~/furconai/i

    atts.each do |att|
      att.css("div.image").each do |pic|
        si = SocialSite::Item.new()
        si.site = "Nitter"
        si.date = Time.now.to_i
        si.url = tweet_url
        si.source = si.url
        si.type = "image"
        thumb_url = pic.css("img")[0]["src"]
        si.thumb = thumb_url
        si.thumb = "#{instance_base_url}#{thumb_url}"
        si.identifier = si.thumb
        items << si
      end

      att.css("div.video-container").each do |vid|
        si = SocialSite::Item.new()
        si.site = "Nitter"
        si.date = Time.now.to_i
        si.url = tweet_url
        si.source = si.url
        si.type = "video"
        thumb_url = vid.css("img")[0]["src"]
        si.thumb = "#{instance_base_url}#{thumb_url}"
        #si.thumb = "https://pbs.twimg.com/"+URI.decode_www_form_component(thumb_url.scan(/(\/(amplify|ext_tw)_video_thumb.*)$/)[0][0])
        si.identifier = si.thumb
        items << si
      end
    end

    cards.each do |card|
      card.css("div.card-container").each do |thing|
        if thing['href'] and thing['href'].start_with?("http")
          si = SocialSite::Item.new()
          si.site = "Nitter"
          si.date = Time.now.to_i
          si.url = tweet_url
          si.source = si.url
          si.type = "link"
          si.identifier = thing['href']
          if thing.css("div.card-image")
            thumb_url = thing.css("div.card-image img")[0]["src"]
            si.thumb = "#{instance_base_url}#{thumb_url}"
#            si.thumb = "https://pbs.twimg.com/"+URI.decode_www_form_component(thumb_url.scan(/(\/card_img.*)$/)[0][0])
          end
          items << si
        end
      end
    end
    return items.uniq()
  end

  def fetch_one_page(tag, current_index)
    items = []
    search_url = "#{@nitter_instance}/search?g=tweets&q=#{URI.encode_www_form_component(tag)}"
    if current_index != ""
      search_url += "&cursor=#{current_index}"
    end
    debug("Parsing #{search_url}") 
    begin
    r = Nokogiri::HTML.parse(Net::HTTP.get(URI.parse(search_url)))
    rescue Exception => e
      puts search_url
      pp e
      raise e
    end

    r.css('div.timeline-item').each do |tweet|
      next if tweet.text == "Load newest"
      begin
      items = items + parse_one_tweet(tweet)
      rescue Exception => e
        pp tweet.to_html
        raise e
      end
    end

    new_index = r.css("div.show-more a")[-1]["href"].scan(/cursor=(.*)(^\/&#)?$/)[0][0]
    return new_index, items.uniq
  end

  def fetch_new_tag(tag, max_results:80)
    items = []
    current_index = ""

    while items.size() < max_results 
      current_index, new_items = fetch_one_page(tag, current_index)
      items += new_items
    end

    return items
  end
end

if __FILE__ == $0
  t = NitterSite.new(nitter_instance:"http://localhost:8080")
  res = t.fetch_new_tag('test')
  res.each do |s|
    pp s
  end
end
