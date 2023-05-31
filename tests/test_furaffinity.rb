#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestFA < TestSite
    require_relative "../sites-enabled/furaffinity.rb"

    def _testItemSpecific(item)
      begin
      assert_block { item.url =~ /^https:\/\/www.fxfuraffinity.net\/view\/\d+\/$/}
      assert_block { item.source =~ /^https:\/\/www.fxfuraffinity.net\/view\/\d+\/$/}
      assert_block { item.thumb=~/^https:\/\/t.furaffinity.net\/[0-9@\-]+.jpg$/}
      rescue Exception => e
        pp item
        raise e
      end
    end

    def testFull()
        _testFull(Furaffinity)
    end
end

