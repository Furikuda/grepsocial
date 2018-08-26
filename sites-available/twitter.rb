require_relative "../site.rb"

class Twitter < SocialSite
    require "base64"
    require "json"
    require "net/http"

    class TwitterError < SocialSite::Error; end

    def initialize()
        super()
        @creds = nil
        @http = nil
    end

    def fetch_new(max_results: 450)
        # Because we need to be careful of rate limiting
        new_items = []
        max_per_tag = max_results/( @tags.size + 1 )
        @tags.each do |tag|
            new_items.concat(fetch_new_tag(tag, max_results: max_per_tag))
        end
        return new_items
    end

    def fetch_new_tag(tag, max_results:50)
        items = []
        result_dict = get_api("/1.1/search/tweets.json?q=#{tag}&result_type=recent&count=max_results")
        begin
            entities = get_entities(result_dict)
            entities.each do |ent|
                si = SocialSite::Item.new()
                si.site = self.class.to_s
                si.identifier =  ent["url"] || ent["source_url"]
                si.thumb = ent["thumb"]
                si.date = Time.now.to_i # get from json?
                si.url = ent["url"] || ent["source_url"]
                si.source = si.url

                if si.url=~/https:\/\/curiouscat.me/
                    next
                end
                items << si
            end
        rescue Exception
            # TODO better exceptioning
            pp result_dict
        end
        return items
    end

    # Private

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

    def load_creds(path:nil)
        path = get_api_file_path(path:path)
        json_content = nil
        File.open(path, 'r') do |f|
            json_content = f.read().strip()
        end
        @creds = JSON.parse(json_content)
        unless @creds["consumer_key"]=~/^[a-zA-Z0-9\-]{25}$/
            raise TwitterError.new("Need a proper Consumer API key in #{path} file")
        end
        unless @creds["secret_key"]=~/^[a-zA-Z0-9\-]{50}$/
            raise TwitterError.new("Need a proper Secret API key in #{path} file")
        end
    end

    def connect()
        load_creds unless @creds
		credentials = Base64.encode64("#{@creds["consumer_key"]}:#{@creds["secret_key"]}").gsub("\n", "")
		headers = {
            "Authorization" => "Basic #{credentials}",
            "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8"
		}
		@http = Net::HTTP.new("api.twitter.com",443)
        @http.use_ssl=true
        @http.ssl_version = 'TLSv1_2'
		res = @http.post("/oauth2/token", "grant_type=client_credentials", headers)
		bearer_token = JSON.parse(res.body)["access_token"]

		@api_auth_header = {"Authorization" => "Bearer #{bearer_token}"}
    end

    def get_api(req)
        connect unless @http
        json = nil
        begin
            resp = @http.get(URI.encode(req),@api_auth_header)
            json = JSON.parse(resp.body)
        rescue Net::OpenTimeout => e
            debug "Got error #{e}, retrying"
            sleep 1
            retry
        rescue JSON::ParserError => e
            raise TwitterError.new("Failed to parse JSON in response #{resp.body} for request #{req}")
        end
        return json
    end

    def get_entities(json)
        if not json
            raise TwitterError.new("can't get_entities() on nil")
        end
        entities = []
        json["statuses"].sort{|x, y| DateTime.parse(y['created_at']) <=> DateTime.parse(x['created_at'])}.each do |tweet|
            entities.concat(parse_entities(tweet["entities"])) if tweet["entities"]
            entities.concat(parse_entities(tweet["extended_entities"])) if tweet["extended_entities"]
        end if json["statuses"]
        entities.concat(parse_entities(json["entities"])) if json["entities"]
        entities.concat(parse_entities(json["extended_entities"])) if json["extended_entities"]
        return entities
    end

    def validate_item_dict(item)
        ["thumb", "type"].each do |check|
            raise TwitterError.new("#{check} is nil") unless item[check]
        end
        if not (item["url"] || item["source_url"])
            raise TwitterError.new("need at least one of url or source_url key")
        end
    end

    def parse_entities(e)
        items = []
        (e["media"] || []).each do |m|
            if m["media_url"]=~/pbs.twimg.com\/ext_tw_video_thumb/
                next
            end
            item = {
                "source_url" => m["expanded_url"],
                "thumb" => m["media_url_https"],
                "type" => m["type"]
            }
            begin
                validate_item_dict(item)
            rescue StandardError => e
                msg = "#{item} is badly formed.\n Source: #{m}"
                raise TwitterError.new(msg), cause: e
            end
            items << item
        end
        (e["urls"] || []).each do |url|
            case url["expanded_url"]
            when /https:\/\/twitter.com\/.*\/status\/([0-9]+)/
                twitid = $1
                json = get_api("/1.1/statuses/show.json?id=#{twitid}&include_entities=true&tweet_mode=extended&trim_user=true")
                if json and json["entities"]
                    items.concat(parse_entities(json["entities"]))
                end
            when /pinterest.com/
                next
            end
            item = {
                "type" => "url",
                "url" => url["expanded_url"],
                "thumb" => ""
            }
            begin
                validate_item_dict(item)
            rescue StandardError => e
                msg = "#{item} is badly formed.\n Source: #{m}"
                raise TwitterError.new(msg), cause: e
            end
            items << item
        end
        return items
    end
end
