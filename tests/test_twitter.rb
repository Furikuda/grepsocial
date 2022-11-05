#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestTwitter < TestSite

    require_relative "../sites-enabled/twitter.rb"

    require "tempfile"

    def testGetApiFilePath
        t = TwitterSite.new()
        assert_raise TwitterSite::TwitterError do
            t.get_api_file_path(path:"fakecreds")
        end
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("lol")
            t = TwitterSite.new()
            assert_equal(f.path, t.get_api_file_path(path: f.path))
        }
    end

    def _testItemSpecific(item)
        assert_block {item.identifier =~/https?:\/\//}
        assert_block {item.url =~ /https?:\/\//}
    end

    def testFull()
        _testFull(TwitterSite)
    end

end
