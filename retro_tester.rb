require 'nokogiri'
require 'net/http'
require 'uri'
require 'open-uri'
require 'json'
require_relative 'google_stock_scraper'
require_relative 'stock_api_toucher'
require_relative 'historical_data'
require 'date'

# require_relative 'retro_tester'

class RetroTester
  attr_reader :api_toucher, :years_of_data, :minimum_percent_down_to_buy,
              :maximum_percent_down_to_buy, :percent_up_to_sell,
              :year_slope_ceiling, :year_slope_floor, :month_slope_ceilng,
              :check_volatility, :month_slope_floor,
              :radical_period, :radical_tolerance

  attr_accessor :data_arry, :total_output, :results

  def initialize(check_volatility: false, years_of_data: 5)
    @data_arry = GoogleStockScraper.new.results
    @api_toucher = StockApiToucher.new
    @years_of_data = years_of_data
    @minimum_percent_down_to_buy = -3
    @maximum_percent_down_to_buy = -50
    @percent_up_to_sell = 2
    @year_slope_ceiling = 0.046
    @year_slope_floor = 0.02
    @month_slope_ceilng = 0.046
    @month_slope_floor = -0.5
    @check_volatility = check_volatility
    @radical_period = 15
    @radical_tolerance = 0.3
    @total_output = []
    @results = []
  end

  def multi_stock_retro_test
    puts "kibot login"
    kibot_login

    data_arry.each_with_index{ |stock, index|
      puts "#{index} out of #{data_arry.length}"
      result = retro_test(stock[:symbol])
      (total_output << result) unless result.nil? || result[:results].empty?
    }

    #File.write('results/retro_test_down_4_up_2.txt', total_output.to_json)
    save_results
    return total_output
  end

  def save_results
    total_output.each{|stock| results << stock[:results]}
    results.flatten!
  end

  def retro_test(sym="ge")
  # grab historical data for past 5 years
    years = years_of_data
    arry = x_years_data(sym, years)
    if arry.is_a? Array
      # look at data for each day starting at 1 year out,
      start = arry.count / years
      results = []
      results_index = 0
      summery_data = {symbol: sym, number_of_buys: 0, number_of_sells: 0, longest_wait: 0}

      (arry.count - start).times { |i|   # [251..1256]

       today = arry[i+start] # the day in history we care about
       yesterday = arry[i+start-1]
       day_change = today[4].to_f - yesterday[4].to_f
       percent_change = (day_change / yesterday[4].to_f)*100
       x = []; y = []

        # puts "#{today[0]}- closing price: #{today[4]}  percent change: #{percent_change}"

       # if it passes algorithm
       if percent_change < minimum_percent_down_to_buy &&
          percent_change > maximum_percent_down_to_buy

        year_slope = x_days_slope(arry, i, 251, years_of_data)[1]
        month_slope = x_days_slope(arry, i, 30, years_of_data)[1]
        week_slope = x_days_slope(arry, i, 10, years_of_data)[1]

        last_year_of_data_from_this_point_in_history = arry[i..i+start]

        if check_volatility
          is_low_volatility = !erratic?(last_year_of_data_from_this_point_in_history, radical_period, radical_tolerance)
        else
          is_low_volatility = true
        end


         #puts "slope of year upto today: #{slope}"
          if year_slope > year_slope_floor && year_slope < year_slope_ceiling && month_slope < month_slope_ceilng && month_slope > month_slope_floor && is_low_volatility
            #puts "good enough"
            results[results_index] = {symbol: sym, year_slope: year_slope, month_slope: month_slope, week_slope: week_slope, bought: today}
            summery_data[:number_of_buys]+=1
            # find next date at which sell condition met
            range = (i+start+1)..arry.count-1

            #puts "range of days to look for sell: #{range}"

            range.each { |terc_i|
              #puts "check sell on day #{terc_i}"
              could_be = arry[terc_i]
              daily_high = arry[terc_i][2].to_f

              goal = (today[4].to_f) * (1+(0.01 * percent_up_to_sell))
              if daily_high >= goal
                # add to element to purchase array
                results[results_index][:sold] = could_be

                summery_data[:number_of_sells]+=1

                bought_date = DateTime.strptime(results[results_index][:bought][0], '%m/%d/%Y')
                sold_date = DateTime.strptime(results[results_index][:sold][0], '%m/%d/%Y')
                days_till_sell = (sold_date - bought_date).to_i

                results[results_index][:days_before_sell] = days_till_sell
                if results[results_index][:days_before_sell] > summery_data[:longest_wait]
                  summery_data[:longest_wait] = results[results_index][:days_before_sell]
                end

                results_index += 1
                break
              end
            }

            unless results[results_index].nil?
              if results[results_index][:sold].nil?
                results[results_index][:sold] = "not yet sold"

                bought_date = DateTime.strptime(results[results_index][:bought][0], '%m/%d/%Y')
                sold_date = DateTime.strptime(arry[-1][0], '%m/%d/%Y')
                days_till_sell = (sold_date - bought_date).to_i

                results[results_index][:days_before_sell] = days_till_sell
                if results[results_index][:days_before_sell] > summery_data[:longest_wait]
                  summery_data[:longest_wait] = results[results_index][:days_before_sell]
                end


                results_index += 1
              end

            end
          end
       end

      }

      x = 0
      results.each{ |purchase| x += purchase[:days_before_sell]}
      summery_data[:average_days_before_sell] = x/results.length unless results.empty?

      return {summery: summery_data, results: results}
    else
      return nil
    end

  end

  def x_days_slope(data, index, days, years_of_data)
    x = []; y = []
    start = data.count / years_of_data
    days.times { |sub_i| x[sub_i] = sub_i; y[sub_i] = data[index+start-(days-sub_i)][1].to_f; }
    lineFit = LineFit.new; lineFit.setData(x,y)
    lineFit.coefficients
  end

  def x_day_sales(x)
    results.select{ |purchase| purchase[:days_before_sell] == x }
  end

  def x_to_y_day_sales(x,y)
    results.select{ |purchase| purchase[:days_before_sell] >= x && purchase[:days_before_sell] <= y }
  end

  def percent_of_total_sales(x)
    (x / results.count.to_f * 100).round(2)
  end

  def print_stats
    unless total_output.empty?
      unresolved_count = results.select{ |x| x[:sold] == "not yet sold" }.count
      puts "***"
      puts "total purchases: #{results.count}"
      puts "1 day before sale: #{x_day_sales(1).count}, #{percent_of_total_sales(x_day_sales(1).count)}% of purchases"
      puts "2 days before sale: #{x_day_sales(2).count}, #{percent_of_total_sales(x_day_sales(2).count)}% of purchases"
      puts "3-5 days before sale: #{x_to_y_day_sales(3,5).count}, #{percent_of_total_sales(x_to_y_day_sales(3,5).count)}% of purchases"
      puts "6-10 days before sale: #{x_to_y_day_sales(6,10).count}, #{percent_of_total_sales(x_to_y_day_sales(6,10).count)}% of purchases"
      puts "11-20 days before sale: #{x_to_y_day_sales(11,20).count}, #{percent_of_total_sales(x_to_y_day_sales(11,20).count)}% of purchases"
      puts "21-50 days before sale: #{x_to_y_day_sales(21,50).count}, #{percent_of_total_sales(x_to_y_day_sales(21,50).count)}% of purchases"
      puts "51-100 days before sale: #{x_to_y_day_sales(51,100).count}, #{percent_of_total_sales(x_to_y_day_sales(51,100).count)}% of purchases"
      puts "101-365 days before sale: #{x_to_y_day_sales(101,365).count}, #{percent_of_total_sales(x_to_y_day_sales(101,365).count)}% of purchases"
      puts "366-1000 days before sale: #{x_to_y_day_sales(366,1000).count}, #{percent_of_total_sales(x_to_y_day_sales(366,1000).count)}% of purchases"
      puts "unresolved sales: #{unresolved_count}, #{percent_of_total_sales(unresolved_count)}% of purchases"
      puts "***"

    else
      multi_stock_retro_test
      print_stats
    end
  end
end


 #  tester = RetroTester.new(check_volatility: false)
 # tester.print_stats
