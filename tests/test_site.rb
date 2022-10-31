#!/usr/bin/ruby
# encoding: utf-8

require "test/unit"

class TestSocialSite < Test::Unit::TestCase

    require_relative "../site.rb"

    class FakeSite < SocialSite

        def initialize()
            super()
            set_database(db:Sequel.sqlite())
        end
    end

    class FakeSocialSiteItem < SocialSite::Item
    end

    def testAddItem()
        f = FakeSite.new()
        fi = FakeSocialSiteItem.new()
        fi.identifier = "fake_identifier"
        f.add_item(fi)
        f.add_item(fi) # Shouldn't raise
        assert_equal(1, f.count_items)
    end

    def testAddAll()
        f = FakeSite.new()
        fi1 = FakeSocialSiteItem.new()
        fi1.identifier = "fake_identifier1"
        fi2 = FakeSocialSiteItem.new()
        fi2.identifier = "fake_identifier2"
        f.add_all([fi1, fi2])
        assert_equal(2, f.count_items)
    end

    def testBuildList()
        Dir.glob("sites-enabled/*.rb").each do |site|
            load "#{site}"
        end
        assert_equal(["Flickr", "Furaffinity", "TestSocialSite::FakeSite", "TwitterSite", "Youtube"], SocialSite.sites_class_list().map{|x| x.to_s}.sort)
    end
end
