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

    def testLoadCredsBadJson()
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("lol")
            t = TwitterSite.new()
            assert_raise JSON::ParserError do
                t.load_creds(path: f.path)
            end
        }
    end

    def testLoadCreds()
        TwitterSite.attr_reader :creds
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("{\"consumer_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaa\",\n\"secret_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}")
            f.close
            t = TwitterSite.new()
            t.load_creds(path: f.path)
            assert_equal("aaaaaaaaaaaaaaaaaaaaaaaaa", t.creds["consumer_key"])
            assert_equal("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", t.creds["secret_key"])
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
