#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestTwitter < TestSite

    require_relative "../sites-enabled/twitter.rb"

    require "tempfile"

    def testGetApiFilePath
        t = Twitter.new()
        assert_raise Twitter::TwitterError do
            t.get_api_file_path(path:"fakecreds")
        end
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("lol")
            t = Twitter.new()
            assert_equal(f.path, t.get_api_file_path(path: f.path))
        }
    end

    def testLoadCredsBadJson()
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("lol")
            t = Twitter.new()
            assert_raise JSON::ParserError do
                t.load_creds(path: f.path)
            end
        }
    end

    def testLoadCredsBadData()
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("{}")
            f.close
            t = Twitter.new()
            assert_raise Twitter::TwitterError do
                t.load_creds(path: f.path)
            end
        }
    end

    def testLoadCreds()
        Twitter.attr_reader :creds
        Tempfile.open("foo", tmpdir = Dir.tmpdir) {|f|
            f.write("{\"consumer_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaa\",\n\"secret_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}")
            f.close
            t = Twitter.new()
            t.load_creds(path: f.path)
            assert_equal("aaaaaaaaaaaaaaaaaaaaaaaaa", t.creds["consumer_key"])
            assert_equal("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", t.creds["secret_key"])
        }
    end

    def testConnect()
        Twitter.attr_reader :api_auth_header
        t = Twitter.new()
        tempfile = nil
        expected_regexp = /^Bearer .{112}$/
        begin
            api_file_path = t.get_api_file_path()
        rescue RuntimeError
            warn "Can't properly test connect() without API creds set in #{api_file_path}"
            tempfile = Tempfile.open("foo", tmpdir = Dir.tmpdir)
            api_file_path = tempfile.path
            tempfile.write("{\"consumer_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaa\",\n\"secret_key\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}")
            tempfile.close
            t.load_creds(path: tempfile.path)
            expected_regexp = /^Bearer $/
        end

        t.connect()
        assert_match(expected_regexp, t.api_auth_header["Authorization"])
    end

    def _testItemSpecific(item)
        assert_block {item.identifier =~/https?:\/\//}
        assert_block {item.url =~ /https?:\/\//}
    end

    def testFull()
        _testFull(Twitter)
    end

end
