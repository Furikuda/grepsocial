require_relative "../site.rb"

class Youtube < SocialSite
    require "json"
    require "net/http"

    class YoutubeError < SocialSite::Error; end

    def initialize()
        super()
        @api_key = nil
    end

    def fetch_new_tag(tag, max_results:0)
        items = []
        json = api_search(tag)
        json.dig("items").each do |json_item|
            items << json_to_item(json_item)
        end
        return items
    end

    # Private stuff

    def get_api_file_path()
        path = File.join(File.dirname(File.basename(__FILE__)), ".ytapikey")
        unless File.exist?(path)
            warn "No #{path} file, Youtube might not work properly"
            return nil
        end
        return path
    end

    def get_api_key()
        path = get_api_file_path()
        api_key = nil
        File.open(path, 'r') do |f|
            api_key = f.read().strip()
        end
        unless api_key=~/^[a-zA-Z0-9\-]{39}$/
            raise YoutubeError.new("Need a proper Youtube API key in #{path} #{api_key}")
        end
        return api_key
    end

    def api_search(tag, max_results=0, max_date=nil)
        unless @api_key
            @api_key = get_api_key()
        end
        query  = "key=" + @api_key
        query += "&part=id,snippet"
        if max_results > 0
            query += "&maxResults=#{max_results}"
        else
            query += "&maxResults=50"
        end
        if max_date
            query += "&publishedAfter="+max_date.utc.strftime('%FT%TZ')
        end
        query += "&type=video"
        query += "&q="+URI.encode_www_form_component(tag)
        uri = URI("https://www.googleapis.com/youtube/v3/search?"+query)

        json = nil
        Net::HTTP.start(
            uri.host, uri.port,
            open_timeout: 5, read_timeout: 5,
            use_ssl: true
        ) do |http|
            request = Net::HTTP::Get.new uri
            response = http.request request
            json = JSON.parse(response.body)
        end
        return json
    end

    def json_to_item(json_item)
        si = SocialSite::Item.new()
        si.identifier = json_item.dig("id", "videoId")
        si.title = json_item.dig("snippet", "title")
        si.thumb = json_item.dig("snippet", "thumbnails", "medium", "url")
        si.date = DateTime.strptime(json_item.dig("snippet", "publishedAt")[/^(.+)\./,1], "%FT%T").to_time.to_i
        si.url = "https://www.youtube.com/watch?v=#{si.identifier}"
        si.site = self.class.to_s
        return si
    end
end
