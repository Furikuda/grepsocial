#!/usr/bin/ruby
# encoding: utf-8

Encoding.default_external = Encoding::UTF_8

require "pp" # don't remove, this adds the pretty_inspect method
require "securerandom"
require "sequel"
require "sinatra"
require "slim"

require_relative "./site.rb"


set :bind, '0.0.0.0'

set :public_folder, File.join(File.dirname(__FILE__), "public")
configure do
  enable :sessions

  set :database, Sequel.sqlite("db/grepsocial.sqlite")
  set :items_cache, {}
end

use Rack::Auth::Basic, "Restricted Area" do |username, password|
      username == 'toto' and password == 'tyty'
end

use Rack::Session::Cookie,
    :key => 'rack.session',
    :path => '/',
    :expire_after => 2592000, # In seconds
    :secret => SecureRandom.hex

def mark_seen(item)
    settings.database[:grepsocial].where(site:item[:site], identifier:item[:identifier]).update(seen: true)
end

def get_unseen_items(nb:10)
    rows = settings.database[:grepsocial].where(seen:false).order(Sequel.asc(:date)).limit(nb).map{|row| row.to_h}.each{|row| row['debug'] = row.pretty_inspect }
    return rows
end

get "/unseen" do
    nb = 10
    if params[:nb]=~/^(\d+)$/
        if nb < 1000
            nb = $1.to_i
        end
    end

    results = get_unseen_items(nb:nb)
    randid = rand(10000000000)
    settings.items_cache[randid] = results
    content_type :json
    res = {'sessid'=> randid, 'data' => results}
    return res.to_json
end

post "/markseen" do
    sessid = params[:sessid].to_i
    if sessid
        seen = settings.items_cache[sessid] || []
        seen.each do |item|
            mark_seen(item)
        end
    end
    redirect "https://grepsocial.opm.duckdns.org/"

end

get '/' do
    slim :main
end
