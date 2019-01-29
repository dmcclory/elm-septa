# myapp.rb

require 'sucker_punch'
require 'sinatra/base'
require 'http'
require 'json'

class SimpleCache
  attr_reader :data

  def initialize(data="")
    @cache = { inbound: {}, outbound: {} }
    @data = data
  end

  def update(direction, line_name,  data)
    @cache[direction][line_name] = JSON.parse(data)
    res = @cache.map { |direction, lines|
      [direction, lines.map { |k,v| { name: k, trains: v } }]
    }.to_h
    @data = JSON.dump(res)
  end

  def read
    @data
  end
end

class LineFetcher
  include SuckerPunch::Job

  def perform(line, cached_response)
    self.class.perform_in(60, line, cached_response)
    fetch_and_cache(line, :outbound, cached_response)
    fetch_and_cache(line, :inbound, cached_response)
  end

  def fetch_and_cache(line, direction, cached_response)
    args = (direction == :inbound) ?
      [line[:origin], "Market East"] : ["Market East", line[:origin]]
    url = build_url(*args)
    data = get_data(url)
    cached_response.update(direction, line[:line_name], data)
  end

  def build_url(origin, destination, limit=5)
    "http://www3.septa.org/hackathon/NextToArrive/#{origin}/#{destination}/#{limit}"
  end

  def get_data(url)
    response = Http.get(url)
    body = response.body
    puts "got a ??? response code: #{response.code}"
    result = body.take_while { |i| i != nil }
    puts "going to return this as json: #{result.join}"
    result.join
  end
end


LINES = [
	{ origin: "Airport Terminal E-F", line_name: "Airport" },
	{ origin: "Chestnut Hill East", line_name: "Chestnut Hill East" },
	{ origin: "Chestnut Hill West", line_name: "Chestnut Hill West" },
	{ origin: "Fox Chase", line_name: "Fox Chase" },
	{ origin: "Lansdale", line_name: "Lansdale/Doylestown" },
	{ origin: "Manayunk", line_name: "Manayunk/Norristown" },
	{ origin: "Elwyn Station", line_name: "Media/Elwyn" },
	{ origin: "Malvern", line_name: "Paoli/Thorndale" },
	{ origin: "Trenton", line_name: "Trenton" },
	{ origin: "Warminster", line_name: "Warminster" },
	{ origin: "West Trenton", line_name: "West Trenton" },
	{ origin: "Wilmington", line_name: "Wilmington/Newark" },
]

CACHED_RESPONSE = SimpleCache.new()
LINES.each do |line|
	LineFetcher.perform_in(rand(0..20), line, CACHED_RESPONSE)
end

class App < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + '/build'

  get '/lines' do
    CACHED_RESPONSE.data
  end

  def build_url(origin, destination, limit=5)
    "http://www3.septa.org/hackathon/NextToArrive/#{origin}/#{destination}/#{limit}"
  end

  def get_data(url)
    response = Http.get(url)
    body = response.body
    puts "got a ??? response code: #{response.code}"
    result = body.take_while { |i| i != nil }
    puts "going to return this as json: #{result.join}"
    result.join
  end

  get '/forward/*' do |path|
    content_type :json
    url = "http://www3.septa.org/hackathon/NextToArrive/#{path}"
    get_data(url)
  end
end
