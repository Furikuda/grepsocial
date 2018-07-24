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
set :show_exceptions, false

use Rack::Auth::Basic, "Restricted Area" do |username, password|
      username == 'admin' and password == 'pwd'
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
    rows = settings.database[:grepsocial].where(seen:false).limit(nb).map{|row| row.to_h}.each{|row| row['debug'] = row.pretty_inspect }
    return rows
end

set :database, Sequel.sqlite("grepsocial.sqlite")
set :items_cache, {}

before do
    Dir.glob(File.join("sites-enabled", "*.rb")).each do |site|
        load "#{site}"
    end
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
    session["randid"] = randid
    content_type :json
    return results.to_json
end

post "/markseen" do
    if session
        seen = settings.items_cache[session[:randid]] || []
        seen.each do |item|
            mark_seen(item)
        end
    end
    redirect "https://#{request.host}/"

end

get '/' do
    slim :main
end
