require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require 'openssl'

class GoogleStockScraper

  number_of_stocks_considered = 4000
  lowest_price = 1
  highest_price = 50

  #capture stock screener html
  def capture
    uri = URI.parse("https://www.google.com/finance?start=0&num=4000&q=%5B(exchange%20%3D%3D%20%22NASDAQ%22)%20%26%20(last_price%20%3E%201)%20%26%20(last_price%20%3C%2050)%5D&restype=company&noIL=1")
    doc = Nokogiri::HTML(open(uri,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
    puts "data captured"
    doc
  end

  #scrape symbols and prices
  def scrape
    doc = capture
    puts "scraping..."
    symbols = doc.css("tr.snippet td.symbol").map &:text
    tickers = doc.css("tr.snippet td.rgt.nwp").map &:text
    puts "data scraped"
    return [symbols, tickers]
  end






  #assemble proper array
  def results
    symbols, tickers = scrape
    puts "organizing..."
    total = []
    symbols.length.times {|c|
      total[c] = {symbol: symbols[c].gsub!("\n",''), price: tickers[c].to_f}
    }
    total
  end
end
