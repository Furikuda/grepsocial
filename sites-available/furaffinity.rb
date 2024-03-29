require_relative "../site.rb"

require "net/http"
require "nokogiri"

class Furaffinity < SocialSite
    class FuraffinityError < SocialSite::Error ; end
    def initialize()
        super()
        @cookie_a = nil
        @cookie_b = nil
    end

    def fetch_new_tag(tag, max_results:0)
      post_data = {
        "q" => tag,
        "page" => "1", 
        "perpage" => "72", 
        "order-by" => "date", 
        "order-direction" => "desc", 
        "do_search" => "Search", 
        "range" => "all", 
        "rating-general" => "on", 
        "rating-mature" => "on", 
        "rating-adult" => "on", 
        "type-art" => "on", 
        "type-flash" => "on", 
        "type-photo" => "on", 
        "type-music" => "on", 
        "type-story" => "on", 
        "type-poetry" => "on", 
        "mode" => "extended"
      }
      res = fa_post("/search/", post_data)

      items = []
      Nokogiri::HTML.parse(res).css('figure').each do |post|
        si = SocialSite::Item.new()
        si.identifier = post['id']
        si.title = post.css('figcaption p a')[0]['title']
        si.thumb = 'https:'+post.css('img')[0]['src']
        si.date = DateTime.now().to_time.to_i
        si.url = "https://www.fxfuraffinity.net"+post.css('a')[0]['href']
        si.source = si.url

        si.site = self.class.to_s
        items << si
        save_pic(si.thumb, 'https://www.furaffinity.net/search/')
      end
      return items
    end

    # Privates

    def save_pic(url, referer)
      # FA doesn't really like hotlinking, let's try to download stuff
      pic_dir = File.join('public', 'pics', 'furaffinity')
      Dir.mkdir(pic_dir) unless File.directory?(pic_dir)
      pic_path = File.join(pic_dir, url.split('/')[-1])
      unless File.exist?(pic_path)
        pic = fa_pic_get(url, referer)
        f = File.new(pic_path, 'wb')
        f.write(pic)
        f.close()
      end
    end

    def get_cookies_file_path()
        path = File.join(File.dirname(File.basename(__FILE__)), ".fa_cookies")
        raise FuraffinityError.new("No #{path} file, won't be able to login to FA") unless File.exist?(path)
        return path
    end

    def set_cookies()
        path = get_cookies_file_path()
        begin
          cookies = JSON.parse(File.open(path, 'r'))
          @cookie_a = cookies["cookie_a"]
          @cookie_b = cookies["cookie_b"]
        rescue Exception => e
          raise FuraffinityError.new("Error loading cookies #{e}")
        end
    end

    def fa_pic_get(uri, referer=nil) # lol
      fa_url = URI(uri)
      fa_client = Net::HTTP.new(fa_url.host, fa_url.port)
      fa_client.use_ssl = true
      request = Net::HTTP::Get.new(fa_url.path)
      if referer
        request['Referer'] = referer
      end
      response = fa_client.request(request)
      return response.body
    end

    def fa_post(path, form_data)
      unless @fa_client
        fa_url = URI("https://www.furaffinity.net/")
        @fa_client = Net::HTTP.new(fa_url.host, fa_url.port)
        @fa_client.use_ssl = true
      end
      unless @fa_cookies
        cookies = @fa_client.request(Net::HTTP::Get.new("/"))['set-cookie']
        @fa_cookies = ["a=#{@cookie_a}", "b=#{@cookie_b}", "s=1"].join('; ')+"; "+cookies
      end
      request = Net::HTTP::Post.new(path)
      request.set_form_data(form_data)
      request['Cookie'] = @fa_cookies
      response = @fa_client.request(request)
      return response.body
    end
end
