require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require 'openssl'

class GoogleStockScraper
  attr_reader :number_of_stocks_considered, :lowest_price, :years_back_in_time
  attr_accessor :highest_price

  def initialize(years_back_in_time: 1)
    @number_of_stocks_considered = 10000
    @lowest_price = 1
    @highest_price = 50
    @years_back_in_time = years_back_in_time
    compensate_for_histrical_price
  end

  #capture stock screener html
  def capture
    space = "%20"
    less_than = "%3C"
    greater_than = "%3E"
    equals = "%3D%3D"
    quote = "%22"
    also = "%26"
    orr = "%7C"
                                                                      # [(exchange == "NASDAQ") & (last_price > 1) & (last_price < 50)]
    uri = URI.parse("https://www.google.com/finance?start=0&num=4000&q=%5B(exchange#{equals}#{quote}NASDAQ#{quote})#{also}(last_price#{greater_than}#{lowest_price})#{also}(last_price#{less_than}#{highest_price})%5D&restype=company&noIL=1")


                                                                      # [(exchange == "NASDAQ" | exchange == "NYSE") & (last_price > 1) & (last_price < 50)]
    #uri = URI.parse("https://www.google.com/finance?start=0&num=6000&q=%5B(exchange#{equals}#{quote}NASDAQ#{quote}#{orr}exchange#{equals}#{quote}NYSE#{quote})#{also}(last_price#{greater_than}#{lowest_price})#{also}(last_price#{less_than}#{highest_price})%5D&restype=company&noIL=1")

                                                                      # [(exchange == "NASDAQ" | exchange == "NYSE") & (last_price > 1) & (last_price < 50)]
    #uri = URI.parse("https://www.google.com/finance?start=0&num=6000&q=%5B(exchange#{equals}#{quote}NASDAQ#{quote}#{orr}exchange#{equals}#{quote}NYSE#{quote})#{also}(last_price#{greater_than}#{lowest_price})#{also}(last_price#{less_than}#{highest_price})%5D&restype=company&noIL=1")

                                                                      # [(exchange == "NASDAQ" | exchange == "NYSE") & (last_price > 1) & (last_price < 50)]
    #uri = URI.parse("https://www.google.com/finance?start=0&num=6000&q=%5B(exchange#{equals}#{quote}NASDAQ#{quote}#{orr}exchange#{equals}#{quote}NYSE#{quote})#{also}(last_price#{greater_than}#{lowest_price})#{also}(last_price#{less_than}#{highest_price})%5D&restype=company&noIL=1")


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



  def compensate_for_histrical_price
    @highest_price = highest_price + (2 * years_back_in_time)
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

# scraper = GoogleStockScraper.new
# puts scraper.results
