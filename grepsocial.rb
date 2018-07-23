require "fileutils"
require "logger"
require "optparse"
require "sequel"

class GrepSocialOptions

    attr_accessor :loggers,
        :pid_file,
        :sites,
        :tags,
        :tags_file

    DEFAULT_PID_FILENAME = "grepsocial.pid"
    DEFAULT_TAGS_FILENAME = "taglist"

    def initialize()
        # Default values
        stdout_logger = Logger.new(STDOUT)
        stdout_logger.level = Logger::WARN
        @loggers = [stdout_logger]
        @pid_file = File.join(File.dirname(__FILE__), DEFAULT_PID_FILENAME)
        @sites = nil
        @tags = []
        @tags_file = File.join(File.dirname(__FILE__), DEFAULT_TAGS_FILENAME)
    end

    def define_options(parser)
        parser.banner = "Usage: #{__FILE__} [options]"
        parser.separator ""
        parser.separator "Specific options:"

        specify_verbosity(parser)
        specify_logger(parser)
        specify_sites(parser)
        specify_tags(parser)
        specify_tagsfile(parser)

        parser.separator ""
        parser.separator "Common options:"
        parser.on_tail("-h", "--help", "Show this message") do
            puts parser
            exit
        end
    end

    def specify_logger(parser)
        parser.on("--debug-log FILE", "send all debug message to this file, whatever the verbosity set for the script") do |file|
            debug_file_logger = Logger.new(file)
            debug_file_logger.level = Logger::DEBUG
            @loggers << debug_file_logger
        end
    end

    def specify_sites(parser)
        site_classes_list = SocialSite.sites_class_list()
        site_names = site_classes_list.map{|s| s.to_s}
        site_classes_hash = Hash[site_names.zip(site_classes_list)]
        parser.on("--site [SITE]", site_names + ["help"], "select a site to update (#{site_names.join(',')})") do |site|
            if site=="help"
                puts "Available sites: #{site_names.join(', ')}"
                exit
            else
                site_obj = site_classes_hash[site].new()
                site_obj.set_loggers(@loggers)
                (@sites ||= []) << site_obj
            end
        end
    end

    def specify_tags(parser)
        parser.on("--tags a,b,c", Array, "Specify extra tags to search for in all sites") do |tag|
            (@tags ||= []).concat(tag)
        end
    end

    def specify_tagsfile(parser)
        parser.on("--tags_file FILE", "where are tags to search for stored (defaults to #{@tags_file})") do |file|
            @tags_file = file
        end
    end

    def specify_verbosity(parser)
        parser.on("-v", "--verbose", "Be verbose") do |v|
            @loggers[0].level = Logger::INFO
        end
        parser.on("-d", "--debug", "Be very verbose") do |v|
            @loggers[0].level = Logger::DEBUG
        end
    end
end

def get_sites_list_objects(options)
    SocialSite.sites_class_list().map{|k| site_obj = k.new()}.each{|site| site.set_loggers(options.loggers)}
end

class GrepsocialUpdater
    attr_accessor :options
    def initialize()
        Dir.glob(File.join("sites-enabled", "*.rb")).each do |site|
            load "#{site}"
        end
        @options = GrepSocialOptions.new
    end

    def parse_args(args)
        parser = OptionParser.new
        @options.define_options(parser)
        parser.parse!(args)
    end

    def is_running?()
        return File.exist?(@options.pid_file)
    end

    def load_tags()
        if not File.exist?(@options.tags_file)
            info "No such tags file '#{@options.tags_file}', ignoring"
        else
            File.open(@options.tags_file, "r") do |f|
                new_tags = f.readlines().delete_if{|l| l=~/^\s*#.*$/}.map{|x| x.strip}.delete_if{|x| x == ""}
                debug "Loaded tags #{new_tags.join(',')} from #{@options.tags_file}"

                @options.tags.concat(new_tags).uniq!
            end
        end
    end

    def check_options()
        if (@options.sites and @options.sites.empty?)
            raise ArgumentError.new("Please specify some sites to grep")
        end

        if @options.tags.empty?()
            raise ArgumentError.new('Please specify some tags to search for')
        end
    end

    def info(msg)
        @options.loggers.each do |logger|
            logger.info(msg)
        end
    end

    def debug(msg)
        @options.loggers.each do |logger|
            logger.debug(msg)
        end
    end

    def run(args)
        parse_args(args)
        load_tags()
        check_options()
        if is_running?()
            raise "Already running"
        end
        File.open(@options.pid_file, 'w') do |pid_file|
            pid_file.write(Process.pid)
        end
        begin
            count = get_new_items()
            info "Added #{count} items"
        ensure
            FileUtils.rm @options.pid_file
        end
    end

    def get_new_items(sites:nil)
        count = 0

        (@options.sites || get_sites_list_objects(@options)).each do |site|
            info "Updating #{site.class}"
            current_unseen = site.get_unseen_count

            site.set_tags(@options.tags)
            items = site.fetch_new() # TODO: maxdate / maxresults
            site.add_all(items)

            new_items_count = site.get_unseen_count - current_unseen
            info "Found #{new_items_count}"
            count += new_items_count
        end
        return count
    end

end

if __FILE__ == $0
    $DATABASE = Sequel.sqlite("grepsocial.sqlite")
    runner = GrepsocialUpdater.new()
    runner.run(ARGV)
end
