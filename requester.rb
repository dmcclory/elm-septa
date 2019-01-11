# myapp.rb

require 'sucker_punch'
require 'sinatra'
require 'sinatra/cross_origin'
require 'http'
require 'json'

class LineFetcher
  include SuckerPunch::Job

  def perform(line)
    self.class.perform_in(30, line)
    fetch_and_cache(line, :outbound)
    fetch_and_cache(line, :inbound)
  end

  def fetch_and_cache(line, direction)
    args = (direction == :inbound) ? [line[:origin], "Market East"] : ["Market East", line[:origin]]
    url = build_url(*args)
    data = get_data(url)
    CACHE[direction][line[:line_name]] = JSON.parse(data)
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

CACHE = { inbound: {}, outbound: {} }

LINES.each do |line|
	LineFetcher.perform_in(rand(0..20), line)
end

get '/' do
  'Hello world!'
end

get '/awesome' do
  JSON.dump CACHE.map { |k, v| [k, v.values] }.to_h
end

get '/lines' do
  res = CACHE.map { |direction, lines| [direction, lines.map { |k,v| { name: k, trains: v } } ]}.to_h
  JSON.dump(res)
end

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  200
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
