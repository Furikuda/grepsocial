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
            assert_block { item.date < (Time.now.to_i() + 10)}
            assert_not_nil(item.identifier)
            assert_not_nil(item.url)
            assert_not_nil(item.thumb)
            assert_not_nil(item.site)
        rescue Exception => e
            pp item
            raise e
        end
    end
end
