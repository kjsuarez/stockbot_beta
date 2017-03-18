require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require_relative 'google_stock_scraper'
require_relative 'stock_api_toucher'
require_relative 'historical_data'

class StockBot
  attr_reader :api_toucher, :minimum_percent_change, :symbols, :year_slope_ceiling, :year_slope_floor
  attr_accessor :data_arry

  def initialize()
    @data_arry = GoogleStockScraper.new.results
    @api_toucher = StockApiToucher.new
    @minimum_percent_change = -3
    @year_slope_ceiling = 0.046
    @year_slope_floor = 0.02
    @symbols = symbols
  end

  def symbols
    symbols = []
    data_arry.each_index {|i| symbols[i] = data_arry[i][:symbol] }
    return symbols
  end

  # get yahoo day change data via symbols
  def day_change
    api_toucher.yahoo_multistock_day_change(symbols)
  end

  def add_percent_change
    temp = day_change
    data_arry.each_with_index { |data,i|
      data_arry[i][:percent_change] = (temp[i].to_f / data_arry[i][:price])*100
    }
  end

  def add_last_year_slope
    @data_arry = last_year_slope_multiple(data_arry)
  end

  def add_last_month_slope
    @data_arry = last_month_slope_multiple(data_arry)
  end

  def filter_by_percent_change
    @data_arry = data_arry.select { |data|
      data[:percent_change].to_f < minimum_percent_change
    }
  end

  def filter_by_last_year_slope
    @data_arry = data_arry.select { |data|
      data[:year_slope] > year_slope_floor &&
      data[:year_slope] < year_slope_ceiling
    }
  end

  def filter_by_last_month_slope
    @data_arry = data_arry.select { |data|
      data[:month_slope] < 0.046
    }
  end

  def run
    add_percent_change
    filter_by_percent_change
    add_last_year_slope
    filter_by_last_year_slope
    add_last_month_slope
    filter_by_last_month_slope
  end

  def print
    puts "***"
    data_arry.each {|data| puts data}
    puts "***"
  end

end
