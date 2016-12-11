require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require_relative 'google_stock_scraper'
require_relative 'stock_day_of_api'
require_relative 'historical_data'

# grab stock screener html
# scrape symbols and prices
# assemble proper array
data_arry = GoogleStockScraper.new.results  # [{:symbol,:price},{:symbol,:price},{:symbol,:price}]

# cherrypick based on %down today
  # collect all symbols
symbols = []; day_change = []; percent_change = []
minimum_percent_change = -3
data_arry.each_index {|i| symbols[i] = data_arry[i][:symbol] }

  # divide symbols into url friendly chunks
((symbols.count/1000)+1).times {|n|
  str = symbols[n*1000..((n+1)*1000)-1].to_s
  str.gsub!("\\n", ''); str.gsub!(" ", ''); str.gsub!(/\[\]/, ''); str.gsub!('"',''); str.gsub!(/\[|\]/,'')
  # query yahoo with each chunk
  day_change << yahoo_api_multi_stock(str)
}
day_change.flatten!

puts "day change: #{day_change}"

data_arry.each_with_index{ |data,i| data_arry[i][:percent_change] = (day_change[i].to_f / data_arry[i][:price])*100}
puts "percent change: #{data_arry}"

filtered_data_array = data_arry.select{|data| data[:percent_change].to_f < minimum_percent_change}


puts "filtered by percent change:  #{filtered_data_array}"

# cherrypick based on slope (model after CC)
filtered_data_array = last_year_slope_multiple(filtered_data_array)

puts "data: #{filtered_data_array}"

final_filter = filtered_data_array.select{|data| data[:slope] > 0.02}

puts "***"
final_filter.each {|data| puts data}



#
