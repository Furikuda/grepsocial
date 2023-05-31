#!/usr/bin/ruby
# encoding: utf-8

require_relative "lib.rb"

class TestNitter < TestSite
  require_relative "../sites-enabled/nitter.rb"

  def _testItemSpecific(item)
  end

  def testFull()
    _testFull(Nitter)
  end
end
