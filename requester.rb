# myapp.rb
require 'sinatra'
require 'sinatra/cross_origin'
require 'http'

get '/' do
  'Hello world!'
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


get '/forward/*' do |path|
  content_type :json
  url = "http://www3.septa.org/hackathon/NextToArrive/#{path}"
  body = Http.get(url).body
  res = body.take_while { |i| i != nil }
  res.join
end
