class SocialSite

    require "sequel"

    class Error < RuntimeError
    end

    Item = Struct.new(:identifier, :title, :thumb, :date, :url, :source, :site) do
    end

    def self.sites_class_list()
        return @sites_class_list
    end

    def self.inherited(child)
        (@sites_class_list ||= [] ) << child
    end

    def set_database(db:nil)
        return unless db
        @db = db

        unless @db.table_exists?(:grepsocial)
            @db.create_table :grepsocial do
                primary_key :id
                Fixnum :date, unique: false, empty: false
                # Unique identifier for the post
                String :identifier, unique: true, empty: false
                # "site" this comes from, ie: youtube
                String :site, unique: false, empty: false
                # Mostly not used
                String  :title, unique: false, empty: false
                # URL to the thumbnail picture
                String  :thumb, unique: false, empty: false
                # URL to the post
                String  :url, unique: false, empty: false
                # Points to the source / owner of the pic/video
                String  :source, unique: false, empty: false
                Boolean :seen, unique: false, empty: false, default: false
                Boolean :keep, empty: false, default: false
            end
        end
        @dbh = @db[:grepsocial]
        @loggers = []
    end

    def initialize()
        set_database(db:$DATABASE)
    end

    def set_loggers(loggers)
        @loggers = loggers
    end

    def error(msg)
        @loggers.each do |logger|
            logger.error(msg)
        end
    end

    def warn(msg)
        @loggers.each do |logger|
            logger.warn(msg)
        end
    end

    def info(msg)
        @loggers.each do |logger|
            logger.info(msg)
        end
    end

    def debug(msg)
        @loggers.each do |logger|
            logger.debug(msg)
        end
    end

    def add_all(items)
        items.each do |item|
            add_item(item)
        end
    end

    def add_item(item)
        @dbh.insert_ignore.insert(
            identifier: item.identifier,
            date: item.date,
            title: item.title || "",
            thumb: item.thumb,
            site: item.site,
            source: item.source || "",
            url: item.url
        )
    end

    def count_items()
        return @dbh.count()
    end

    def set_tags(tags)
        @tags = tags
    end

    def fetch_new_tag(tag, max_results: -1)
        raise "Unimplemented"
    end

    def fetch_new(max_results: -1)
        new_items = []
        @tags.each do |tag|
            debug "Searching for #{tag}"
            begin
                new_items.concat(fetch_new_tag(tag, max_results: max_results))
            rescue StandardError => e
                msg = "Failed to fetch_new_tag(#{tag}, max_results: #{max_results}) with error #{e}, continuing with next tag"
                raise SocialSite::Error.new(msg), cause: e
            end
        end
        return new_items
    end

    def dbrow_to_item(row)
        si = Item.new()
        si.identifier = row[:identifier]
        si.date = row[:date]
        si.title = row[:title]
        si.thumb = row[:thumb]
        si.url = row[:url]
        si.site = row[:site]
        si.source = row[:source]
        return si
    end

    def get_unseen_count()
        return @dbh.where(seen:false).count()
    end

    def get_unseen_from_db(nb:10)
        res = []
        @dbh.filter(seen:false).each do |row|
            res << dbrow_to_item(row)
        end
        return res
    end

end
