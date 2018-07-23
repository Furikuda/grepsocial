#!/usr/bin/ruby
# encoding: utf-8

require "test/unit"

class TestGrepSocial < Test::Unit::TestCase

    require_relative "../grepsocial.rb"

    def setup
        @tag_filename = "temp_tags_to_delete"
        @tag_file = File.open(@tag_filename, 'w')
        @tag_file.write(<<~HEREDOC
         sdfqsdf
        qsdf

        #  wsqdfqsdf
        #
        # 
        HEREDOC
        )
        @tag_file.close()
    end

    def teardown
        FileUtils.rm(@tag_filename)
    end

    def testInit()
        runner = GrepsocialUpdater.new()
        options = GrepSocialOptions.new()
        options.tags_file = @tag_filename
        runner.options = options
        runner.load_tags()
        assert_equal(["sdfqsdf", "qsdf"], options.tags)
    end
end
