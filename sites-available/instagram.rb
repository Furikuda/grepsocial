require_relative "../site.rb"

class Instagram < SocialSite
    require "json"
    require "net/http"
    require "nokogiri"

    class InstagramError < SocialSite::Error ; end

    def fetch_new_tag_insta(tag, max_results:50)
        items = []
        uri = URI("https://www.instagram.com/explore/tags/#{URI.encode_www_form_component(tag.gsub(' ',''))}/")
        Net::HTTP.start(
            uri.host, uri.port,
            open_timeout: 5, read_timeout: 5,
            use_ssl: true
        ) do |http|
            request = Net::HTTP::Get.new uri
            response = http.request request
            json_dict = get_json(response.body)
            unless json_dict
                raise InstagramError.new("No Json when querying #{uri}")
            end
            items = get_post_urls(json_dict, max_results:max_results)
        end
        return items
    end

    def fetch_new(max_results: -1)
        # We re-implement this as we need to first list posts, and for each one of them
        #  check if they have a gallery with more pics attached.
        new_posts = []
        @tags.each do |tag|
            debug "Searching for #{tag}"
            begin
                new_posts.concat(fetch_new_tag_insta(tag, max_results: max_results))
            rescue Exception => e
                $stderr.puts e
            end
        end
        new_items = []
        ignore_known_posts(new_posts.sort.uniq)[0..max_results].each do |post_url|
            debug "Checking #{post_url} for good stuff"
            new_items.concat(parse_nodes(get_json(Net::HTTP.get(URI(post_url)))))
        end
        return new_items
    end

    # Privates
    
    def ignore_known_posts(posts_urls)
        @db.create_table(:tempinsta, temp:true) {String :temppost}
        @db[:tempinsta,].import([:temppost], posts_urls)
        res = @db[:tempinsta].exclude(temppost: @dbh.select(:source).where(site: "Instagram")).select_map(:temppost)
        debug "ignored #{posts_urls.size} - #{res.size}"
        @db.drop_table(:tempinsta)
        return res
    end

    def get_post_urls(j, max_results:-1)
        begin
            posts = (j.dig("entry_data", "TagPage", 0, "graphql", "hashtag", "edge_hashtag_to_media", "edges") || []).map{|edge| "https://www.instagram.com/p/#{edge.dig("node", "shortcode")}/"}
        rescue StandardError => e
            raise InstagramError.new("Failed to parse Json #{j}"), cause:e
        end
        return posts[0..max_results]
    end

    def get_json(html)
        j = nil
        page = Nokogiri::HTML.parse(html)
        page.css("script").each do |s|
            if s.to_s=~/window._sharedData = (.+);<\/script>$/i
                j = JSON.parse($1)
            end
        end
        return j
    end

    def parse_nodes(j)
        graphql = j.dig("entry_data", "PostPage", 0, "graphql")
        media = graphql.dig("shortcode_media")
        return parse_media(media)
    end

    def parse_media(media, date:Time.now().to_i)
        begin
            items = []
            case media["__typename"]
            when "GraphSidecar"
                date = media["taken_at_timestamp"] || date
                media.dig("edge_sidecar_to_children", "edges").each do |node|
                    items.concat(parse_media(node["node"], date:date))
                end
            when "GraphImage"
                items << parse_image(media, date)
            when "GraphVideo"
                items << parse_video(media, date)
            else
                raise InstagramError.new("Unknown media type #{media["__typename"]}")
            end
        rescue StandardError => e
            raise InstagramError.new("Unable to parse media #{media}"), cause: e
        end
        return items
    end

    def parse_video(node, date)
        si = SocialSite::Item.new()
        si.identifier = node["id"]
        si.date = date
        si.title = ""
        si.source = "https://www.instagram.com/p/#{node["shortcode"]}/"
        si.thumb = node["display_url"]
        si.url = node["video_url"]
        si.site = self.class.to_s
        return si
    end

    def parse_image(node, date)
        si = SocialSite::Item.new()
        si.identifier = node["id"]
        si.date = date
        si.title = ""
        si.source = "https://www.instagram.com/p/#{node["shortcode"]}/"
        si.thumb = node["display_url"]
        si.url = node["display_url"]
        si.site = self.class.to_s
        return si
    end
end

