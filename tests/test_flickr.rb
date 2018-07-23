#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestFlickr < TestSite

    require_relative "../sites-enabled/flickr.rb"

    def testGetScriptTag()
        html = "<html><script></script><script class='modelExport'>lolilol</script></html>"
        f = Flickr.new()
        res = f.get_script_tag(html)
        assert_equal(Nokogiri::XML::Element, res.class)
        assert_equal("lolilol", res.text)
    end

    def testGetJsonObj()
        txt = %%modelExport: {"lol":"poil"},\n%
        f = Flickr.new()
        res = f.get_json_obj(txt)
        assert_equal({"lol"=>"poil"}, res)
    end

    def testBiggestPic()
        pics = {"sizes"=>{"a"=>{"lol"=>"crap", "width"=>2}, "b"=>{"id"=>"coin", "width"=> 3}}}
        f = Flickr.new()
        res = f.get_biggest_pic(pics)
        assert_equal({"id"=>"coin", "width"=>3}, res)
    end

    def _testItemSpecific(item)
        assert_block { item.url.start_with?("https://c1.staticflickr.com")}
        assert_block { item.source.start_with?("https://www.flickr.com/photos/")}
        assert_equal("", item.title)
    end

    def testFull()
        _testFull(Flickr)
    end
end
