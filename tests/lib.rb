require "test/unit"
require "pp"

class TestSite < Test::Unit::TestCase

    def _testFull(site_class, max_results:5)
        site = site_class.new()
        site.set_database(db: Sequel.sqlite())
        results = site.fetch_new_tag("test", max_results:max_results)
        assert_block {results.size > 0}
        results.each do |result|
            _testItem(result)
            _testItemSpecific(result)
        end
    end

    def _testItem(item)
        begin 
            assert_equal(SocialSite::Item, item.class)
        rescue Exception => e
            pp item
            raise e
        end
        begin
            assert_block { item.date > (Time.now.to_i() - 500000000 )}
        rescue Exception => e
            puts "item.date is too far back in the past"
            pp item
            raise e
        end
        begin
            assert_block { item.date < (Time.now.to_i() + 10)}
        rescue Exception => e
            puts "item.date is in the future"
            pp item
            raise e
        end
        begin
            assert_not_nil(item.identifier)
        rescue Exception => e
            puts "item.identifier is nil"
            pp item
            raise e
        end
        begin
            assert_not_nil(item.url)
        rescue Exception => e
            puts "item.url is nil"
            pp item
            raise e
        end
        begin
            assert_not_nil(item.thumb)
        rescue Exception => e
            puts "item.thumb is nil"
            pp item
            raise e
        end
        begin
            assert_not_nil(item.site)
        rescue Exception => e
            puts "item.site is nil"
            pp item
            raise e
        end
    end
end
