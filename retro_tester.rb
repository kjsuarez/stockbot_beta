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
# screen and collect stocks

#data_arry = GoogleStockScraper.new.results

# The idea is to loop through the history of every possible stock
# day by day, recording when, according to an algorith,
# that stock would be bought and sold

# for each stock
def multi_stock_retro_test
  puts "kibot login"
  kibot_login

  total_output = []
  data_arry = GoogleStockScraper.new.results
  data_arry.each_with_index{ |stock, index|
    puts "#{index} out of #{data_arry.length}"
    result = retro_test(stock[:symbol])
    (total_output << result) unless result.nil? || result[:results].empty?
  }

  File.write('results/retro_test_down_4_up_2.txt', total_output.to_json)

  return total_output
end

def retro_test(sym="ge", p_change_down=-4, p_change_up=2)
# grab historical data for past 5 years
  years = 5
  arry = x_years_data(sym, years)
  if arry.is_a? Array
    # look at data for each day starting at 1 year out,
    start = arry.count / years
    results = []
    results_index = 0
    summery_data = {symbol: sym, number_of_buys: 0, number_of_sells: 0, longest_wait: 0}

    # puts "data array size: #{arry.count}
    #   start index: #{start}"

    (arry.count - start).times { |i|   # [251..1256]

     today = arry[i+start] # the day in history we care about
     yesterday = arry[i+start-1]
     day_change = today[4].to_f - yesterday[4].to_f
     percent_change = (day_change / yesterday[4].to_f)*100
     x = []; y = []

      # puts "#{today[0]}- closing price: #{today[4]}  percent change: #{percent_change}"

     # if it passes algorithm
     if percent_change < p_change_down

      year_slope = x_days_slope(arry, i, 251, 5)[1]
      month_slope = x_days_slope(arry, i, 30, 5)[1]
      week_slope = x_days_slope(arry, i, 10, 5)[1]
       #puts "slope of year upto today: #{slope}"
        if year_slope > 0.02 && year_slope < 0.046 && month_slope < 0.046
          #puts "good enough"
          results[results_index] = {symbol: sym, year_slope: year_slope, month_slope: month_slope, week_slope: week_slope, bought: today}
          summery_data[:number_of_buys]+=1
          # find next date at which sell condition met
          range = (i+start+1)..arry.count-1

          #puts "range of days to look for sell: #{range}"

          range.each { |terc_i|
            #puts "check sell on day #{terc_i}"
            could_be = arry[terc_i]
            best_of = [could_be[1].to_f,could_be[2].to_f,could_be[3].to_f,could_be[4].to_f].max

            goal = (today[4].to_f) * (1+(0.01 * p_change_up))
            if best_of >= goal
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

#retro_test("atvi")
