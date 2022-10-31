#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestFA < TestSite
    require_relative "../sites-enabled/furaffinity.rb"

    def _testItemSpecific(item)
      assert_block { item.url =~ /^https:\/\/www.furaffinity.net\/view\/\d+\/$/}
      assert_block { item.source =~ /^https:\/\/www.furaffinity.net\/view\/\d+\/$/}
      assert_block { item.thumb=~/^https:\/\/t.furaffinity.net\/[0-9@\-]+.jpg$/}
    end

    def testFull()
        _testFull(Furaffinity)
    end
end

