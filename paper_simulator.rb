require_relative 'retro_tester'

tester = RetroTester.new(check_volatility: true)
tester.multi_stock_retro_test
results = tester.results
daily_stats = tester.daily_stats

cash = 1000.0
money_spent_on_stocks = 0
shares_per_buy = 3
years = tester.years_of_data
days_before_stale = 20
back_then = (DateTime.now - (365*years)).to_date
now = (DateTime.now).to_date
dates = (back_then..now)


dates.each{ |day|
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
    profit = day[:bought][:close] * shares_per_buy * 1.02
    #add profit to cash
    cash += profit
    money_spent_on_stocks -= day[:bought][:close] * shares_per_buy
    puts "cash: #{cash}"
    puts "stocks: #{money_spent_on_stocks}"
  }

  # grab purcheses from this date
  buys = results.select { |result|
    (result[:bought][:date]).to_date == day
  }
  # for each of these purchases
  buys.each { |purchase|
    # if you can afford it
    price = purchase[:bought][:close]
    if price * shares_per_buy < cash
      # subtract price from cash
      cash -= price * shares_per_buy
      money_spent_on_stocks += price * shares_per_buy
      # mark purchase as paid for
      purchase[:paid_for] = true
    else
      puts "broke :("
    end
  }

  # cut  losses on stail purchases
  stale_buys = results.select { |result|
    (result[:bought][:date]).to_date == day - days_before_stale &&
    result[:paid_for] == true &&
    result[:sold_prematurely] != true &&
    result[:sold].class == String
  }

  stale_buys.each { |purchase|
    historical_data = daily_stats.detect{|stock| stock[:symbol] == purchase[:symbol]}
    todays_data = data.detect{|day| day[:date].to_date == purchase[:bought][:date]).to_date}
    unless todays_data.nil?
      #check price on this day
      todays_price = todays_data[:close]

      if todays_price < purchase[:bought][:close] * 0.95
        #sell for price on this day
        cash += todays_price * shares_per_buy
        # mark purchase as paid for
        purchase[:sold_prematurely] = true
      end
    end
  }
}
