# myapp.rb

require 'sucker_punch'
require 'sinatra'
require 'sinatra/cross_origin'
require 'http'
require 'json'

class Looper
  include SuckerPunch::Job

  def perform(key)
    CACHE[key] += 1
    puts "hey man, I am a job!"
    puts "gonna request to run myself again in 5 seconds"
    self.class.perform_in(8, key)
  end
end

LINES = [
	{ origin: "Airport Terminal E-F", name: "Airport" },
	{ origin: "Chestnut Hill East", name: "Chestnut Hill East" },
	{ origin: "Chestnut Hill West", name: "Chestnut Hill West" },
	{ origin: "Fox Chase", name: "Fox Chase" },
	{ origin: "Lansdale", name: "Lansdale/Doylestown" },
	{ origin: "Manayunk", name: "Manayunk/Norristown" },
	{ origin: "Elwyn Station", name: "Media/Elwyn" },
	{ origin: "Malvern", name: "Paoli/Thorndale" },
	{ origin: "Trenton", name: "Trenton" },
	{ origin: "Warminster", name: "Warminster" },
	{ origin: "West Trenton", name: "West Trenton" },
	{ origin: "Wilmington", name: "Wilmington/Newark" },
]

CACHE = LINES.map { |l| [l[:origin], 0] }.to_h

CACHE.keys.each do |k|
	Looper.perform_in(rand(0..20), k)
end

get '/' do
  'Hello world!'
end

get '/awesome' do
  JSON.dump CACHE
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
