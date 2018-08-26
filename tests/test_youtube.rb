#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestYoutube < TestSite

    require_relative "../sites-enabled/youtube.rb"

    def setup
        @youtube_obj = Youtube.new()
        @yid = "9bZkp7q19f0"
    end

    def testApiSearch()
        unless @youtube_obj.get_api_file_path()
            warn "No API key, skipping test."
            return
        end
        tag = "gangnam style"
        json = @youtube_obj.api_search(tag, max_results=2)
        assert_equal("youtube#searchListResponse", json["kind"])
        assert_equal(@yid, json.dig("items", 0, "id", "videoId"))
    end

    def testJsonToItem()
        json = {"kind"=>"youtube#searchResult", "etag"=>"\"DuHzAJ-eQIiCIp7p4ldoVcVAOeY/w-j6V3gM8mXzEvH10BgDOwl2bvM\"", "id"=>{"kind"=>"youtube#video", "videoId"=>"9bZkp7q19f0"}, "snippet"=>{"publishedAt"=>"2012-07-15T07:46:32.000Z", "channelId"=>"UCrDkAvwZum-UTjHmzDI2iIw", "title"=>"PSY - GANGNAM STYLE", "description"=>"PSY - 'I LUV IT' M/V @ https://youtu.be/Xvjnoagk6GU PSY - 'New Face' M/V @https://youtu.be/OwJPPaEyqhI PSY - 8TH ALBUM '4X2=8' on iTunes ...", "thumbnails"=>{"default"=>{"url"=>"https://i.ytimg.com/vi/9bZkp7q19f0/default.jpg", "width"=>120, "height"=>90}, "medium"=>{"url"=>"https://i.ytimg.com/vi/9bZkp7q19f0/mqdefault.jpg", "width"=>320, "height"=>180}, "high"=>{"url"=>"https://i.ytimg.com/vi/9bZkp7q19f0/hqdefault.jpg", "width"=>480, "height"=>360}}, "channelTitle"=>"officialpsy", "liveBroadcastContent"=>"none"}}
        item = @youtube_obj.json_to_item(json)
        expected_si = SocialSite::Item.new(
            "9bZkp7q19f0", "PSY - GANGNAM STYLE", "https://i.ytimg.com/vi/9bZkp7q19f0/mqdefault.jpg", 1342338392, "https://www.youtube.com/watch?v=9bZkp7q19f0")
        expected_si.site = "Youtube"
        expected_si.source = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        assert_equal(expected_si, item)
    end

    def _testItemSpecific(item)
    end

    def testFull()
        _testFull(Youtube)
    end
end
