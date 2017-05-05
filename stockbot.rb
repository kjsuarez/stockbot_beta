require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require_relative 'google_stock_scraper'
require_relative 'stock_api_toucher'
require_relative 'historical_data'

class StockBot
  attr_reader :api_toucher, :minimum_percent_change, :minimum_percent_down_to_buy,
              :maximum_percent_down_to_buy, :symbols, :year_slope_ceiling,
              :year_slope_floor, :check_volatility, :radical_period, :radical_tolerance
  attr_accessor :data_arry

  def initialize(check_volatility: false)
    @data_arry = GoogleStockScraper.new.results
    @api_toucher = StockApiToucher.new
    @minimum_percent_change = -3
    @minimum_percent_down_to_buy = -5
    @maximum_percent_down_to_buy = -10
    @year_slope_ceiling = 0.046
    @year_slope_floor = 0.02
    @check_volatility = check_volatility
    @radical_period = 15
    @radical_tolerance = 0.3
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
      data[:percent_change].to_f > minimum_percent_down_to_buy &&
      data[:percent_change].to_f < maximum_percent_down_to_buy
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

  def filter_by_erratic_nature
    if check_volatility
      @data_arry = data_arry.select { |data|
        !erratic?(x_years_data(data[:symbol], 1), radical_period, radical_tolerance)
      }
    end
  end

  def filter_by_maturaty
    @data_arry = data_arry.select { |data|
      data_is_mature?(x_years_data(data[:symbol], 5))
    }
  end

  def run
    add_percent_change
    filter_by_percent_change
    add_last_year_slope
    filter_by_last_year_slope
    add_last_month_slope
    filter_by_last_month_slope
    filter_by_erratic_nature
    filter_by_maturaty
  end

  def print
    puts "***"
    data_arry.each {|data| puts data}
    puts "***"
  end

end
