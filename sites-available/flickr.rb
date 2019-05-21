require_relative "../site.rb"

class Flickr < SocialSite
    require "json"
    require "net/http"
    require "nokogiri"

    class FlickrError < SocialSite::Error
    end

    def fetch_new_tag(tag, max_results:0)
        items = []
        uri = URI("https://www.flickr.com/search/?sort=date-posted-desc&safe_search=0&advanced=1&text=#{URI.encode(tag)}")
        Net::HTTP.start(
            uri.host, uri.port,
            open_timeout: 5, read_timeout: 5,
            use_ssl: true
        ) do |http|
            request = Net::HTTP::Get.new uri
            response = http.request request
            script_tag = get_script_tag(response.body)
            json = get_json_obj(script_tag.text)
            items = get_items_from_json(json)[0..(max_results-1)]
        end
        return items
    end

    # Privates

    def get_script_tag(html)
        root = Nokogiri::HTML.parse(html)
        tag = root.css("script.modelExport")
        raise FlickrError.new("Issue finding script.modelExport tag") unless tag.size == 1
        return tag[0]
    end

    def get_json_obj(txt)
        js_arr = txt.split("\n").select{|x| x.strip().start_with?("modelExport")}
        raise FlickrError.new("Issue finding modelExport json object") unless js_arr.size == 1
        json = JSON.parse(js_arr[0][/modelExport: ({.*}),$/, 1])
        return json
    end

    def get_thumb_pic(json)
        begin
            pic_url = (json.dig("sizes", "m") || json.dig("sizes", "s") || json.dig("sizes", "sq"))["displayUrl"]
            return pic_url=~/^https:/ ? pic_url : "https://"+pic_url
        rescue StandardError => e
            msg = "Failed parsing json #{json} (case: #{e})"
            raise FlickrError.new(msg), cause:e
        end
    end

    def get_biggest_pic(json)
        sizes = json["sizes"].values.sort_by{|x| x["width"]}.reverse
        return sizes[0]
    end

    def get_items_from_json(json)
        items = []
        date = Time.now()
        json.dig("main", "search-photos-lite-models", 0, "photos", "_data").each do |u|
            si = SocialSite::Item.new()

            user = u["pathAlias"]
            photo_id = u["id"]
            thumb = get_thumb_pic(u)
            pic_json = get_biggest_pic(u)
            url = pic_json["url"]

            si.identifier = photo_id.to_i
            si.date = date.to_i
            si.title = ""
            si.source = "https://www.flickr.com/photos/#{user}/#{photo_id}"
            si.thumb = thumb
            si.url = "https:"+url
            si.site = self.class.to_s

            items << si
        end
        return items
    end
end
