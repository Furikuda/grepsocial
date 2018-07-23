#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestInstagram < TestSite

    require_relative "../sites-enabled/instagram.rb"

    def _testItemSpecific(item)
        begin
            assert_block { item.url=~/https:\/\/.+.cdninstagram.com\//}
            assert_block { item.source.start_with?("https://www.instagram.com/")}
            assert_equal("", item.title)
        rescue Exception => e
            pp item
            raise e
        end
    end

    def testSinglePicPost()
        i = Instagram.new()
        html = Net::HTTP.get(URI.parse("https://www.instagram.com/p/Bld1RMzH5Wb/"))
        items = i.parse_nodes(i.get_json(html))
        assert_equal(1, items.size)
        assert_equal("1827851302221092251", items[0].identifier)
        assert_block { items[0].url =~ /https:\/\/.+.cdninstagram.com\/vp\/383aabc5122040a81d7b16adef62fc02\/5BD37AF2\/t51.2885-15\/e35\/37270098_212508599601809_669909671477248000_n.jpg/}
    end

    def _testSlideShow()
        i = Instagram.new()
        html = Net::HTTP.get(URI.parse("https://www.instagram.com/p/BlB7fLEF8aG/"))
        items = i.parse_nodes(i.get_json(html))
        assert_equal(10, items.size)
        assert_equal("1819997286181529032", items[0].identifier)
        assert_block { items[0].url =~ /https:\/\/.+.cdninstagram.com\/vp\/3ce8defa3ca42f847f9d913045793eba\/5BDFC130\/t51.2885-15\/e35\/36149178_201265627393147_262728887572627456_n.jpg/ }
        assert_equal("1819997255371087153", items[1].identifier)
        assert_block {items[1].url =~ /https:\/\/.+.cdninstagram.com\/vp\/ce032e69e9631712c2b2ba7e57f8c4f3\/5B47BAD9\/t50.2886-16\/36899906_219414945348978_6307552596592355822_n.mp4/ }

    end

    def testFull()
        _testFull(Instagram)
    end

    def testIgnoreKnownPosts()
        i = Instagram.new()
        db = Sequel.sqlite()
        i.set_database(db:db)
        i.add_all(
            0.upto(9).map{|i|
                SocialSite::Item.new("id#{i}", "title#{i}", '', Time.now.to_i,"https://www.instagram.com/p/#{i}/", "https://www.instagram.com/p/#{i}/","Instagram")
            }
        )
        assert_equal(10, db[:grepsocial].count())

        post_urls = 0.upto(5).map{|i| "https://www.instagram.com/p/#{i*2}/"}
        res = i.ignore_known_posts(post_urls)
        assert_equal(["https://www.instagram.com/p/10/"], res)
    end
end

