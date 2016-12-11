require 'net/http'
require 'uri'
require 'openssl'
require 'json'


def login

  hash = {

  }
  json = JSON.generate(hash)

  url = URI.parse('https://api.robinhood.com/api-token-auth/')
  req = Net::HTTP::Post.new(url.path)

  req.body = "username=humbleFool&password=firewalkwithme"

  resp = Net::HTTP.new(url.host, url.port)
  resp.use_ssl = true
  resp.verify_mode = OpenSSL::SSL::VERIFY_NONE
  resp = resp.start{|http| http.request(req) }

  puts resp.body
  return resp
end

def act()

 hash = {
     "email_address": "#{address}",
     "status": "subscribed",
     "merge_fields": {}
 }
 json = JSON.generate(hash)

 url = URI.parse('https://api.robinhood.com/')
 req = Net::HTTP::Post.new(url.path)
 req.basic_auth '5RX20199', '5dfc4617d3eba1ad9c9a2447b583ff5a665794c4'
 req.body = json

 resp = Net::HTTP.new(url.host, url.port)
 resp.use_ssl = true
 resp.verify_mode = OpenSSL::SSL::VERIFY_NONE
 resp = resp.start{|http| http.request(req) }

 puts resp.body
 return resp.body
end

login_hash = login
x = JSON.parse(login_hash.body)["token"]
puts x
