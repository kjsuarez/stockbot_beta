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

  space = "%20"
  less_than = "%3C"
  greater_than = "%3E"
  equals = "%3D"
  quote = "%22"
  also = "%26"
  
  #capture stock screener html
  def capture
                                                                      # [(exchange == "NASDAQ") & (last_price > 1) & (last_price < 50)]
    uri = URI.parse("https://www.google.com/finance?start=0&num=4000&q=%5B(exchange#{space}#{equals}#{equals}#{space}#{quote}NASDAQ#{quote})#{space}#{also}#{space}(last_price#{space}#{greater_than}#{space}1)#{space}#{also}#{space}(last_price#{space}#{less_than}#{space}50)%5D&restype=company&noIL=1")
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
