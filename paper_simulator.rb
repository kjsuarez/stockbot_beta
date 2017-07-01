require_relative 'retro_tester'

tester = RetroTester.new(check_volatility: false, years_of_data: 2)
tester.multi_stock_retro_test
results = tester.results
daily_stats = tester.daily_stats

starting_money = 10000.0
cash = starting_money
money_spent_on_stocks = 0
shares_per_buy = 3
years = tester.years_of_data
days_before_stale = 10
percent_drop_for_premature_sale = 5
back_then = (DateTime.now - (365*years)).to_date
now = (DateTime.now).to_date
dates = (back_then..now)

def stale?(purchase, date, threshold)
  (purchase[:bought][:date]).to_date < date - threshold &&
  purchase[:paid_for] == true &&
  purchase[:sold_prematurely] != true &&
  purchase[:sold].class == String
end

dates.each_with_index{ |day, index|
  puts "day #{index} out of #{dates.count}"
  #look for theoretical sales on this day that are paid for
  sales = results.select { |result|
    result[:sold].class != String &&
    (result[:sold][:date]).to_date == day &&
    result[:paid_for] == true &&
    result[:sold_prematurely] != true
  }
  #for each of these sales
  sales.each { |day|
    #calculate profit (2% of price)
    profit = day[:bought][:close] * day[:shares] * 1.02
    #add profit to cash
    cash += profit
    money_spent_on_stocks -= day[:bought][:close] * day[:shares]
    puts "made #{profit} on sale"
    puts "cash: #{cash}"
    puts "stocks: #{money_spent_on_stocks}"
  }

  # grab purcheses from this date
  buys = results.select { |result|
    (result[:bought][:date]).to_date == day
  }
  # for each of these purchases
  unless buys.empty?
    while(cash > (starting_money/2))
      #puts "inside while loop"
      buys.each{|purchase|
        price = purchase[:bought][:close]
        if cash > (starting_money/2)
          if purchase[:shares]
            purchase[:shares] +=1
          else
            purchase[:shares] = 1
          end
          cash -= price
          money_spent_on_stocks += price
          purchase[:paid_for] = true
        else
          puts "broke :("
        end
        # puts "bought #{purchase[:shares]} shares"
        # puts "cash: #{cash}"
        # puts "stocks: #{money_spent_on_stocks}"
      }
    end
  end


  # buys.each { |purchase|
  #   # if you can afford it
  #   price = purchase[:bought][:close]
  #   if price * shares_per_buy < cash
  #     # subtract price from cash
  #     cash -= price * shares_per_buy
  #     money_spent_on_stocks += price * shares_per_buy
  #     # mark purchase as paid for
  #     purchase[:paid_for] = true
  #   else
  #     puts "broke :("
  #   end
  # }

  # cut  losses on stail purchases
  stale_buys = results.select { |result|
    stale?(result, day, days_before_stale)
  }
  puts "any stale buys? #{!stale_buys.empty?}"
  stale_buys.each { |purchase|
    historical_data = daily_stats.detect{|stock| stock[:symbol] == purchase[:symbol]}
    todays_data = historical_data[:daily_data].detect{|day| day[:date].to_date == purchase[:bought][:date].to_date}
    unless todays_data.nil?
      #check price on this day
      todays_price = todays_data[:close]
      puts "got this far"
      puts "today's price: #{todays_price} vs. price for premature sell: #{purchase[:bought][:close] * (1 - (percent_drop_for_premature_sale * 0.01))}"
      puts "days since bought: #{((day) - ((purchase[:bought][:date]).to_date)).to_i}"
      if todays_price < purchase[:bought][:close] * (1 - (percent_drop_for_premature_sale * 0.01)) || stale?(purchase, day, 50)
        puts "day: #{purchase}"
        #sell for price on this day
        cash += todays_price * purchase[:shares]
        # mark purchase as paid for
        purchase[:sold_prematurely] = true
        puts "SOLD AT A LOSS"
      end
    end
  }
}
