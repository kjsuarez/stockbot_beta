require_relative 'retro_tester'

tester = RetroTester.new(check_volatility: true)
tester.multi_stock_retro_test
results = tester.results

cash = 1000.0
years = tester.years_of_data
back_then = (DateTime.now - (365*years)).to_date
now = (DateTime.now).to_date
dates = (back_then..now)


dates.each{ |day|
  #look for theoretical sales on this day that are paid for
  sales = results.select { |result|
    result[:sold].class != String &&
    (result[:sold][:date]).to_date == day &&
    !result[:paid_for].nil?
  }
  #for each of these sales
  sales.each { |day|
    #calculate profit (2% of price)
    profit = day[:bought][:close] * 3 * 1.02
    #add profit to cash
    cash += profit
    puts "cash: #{cash}"
  }

  # grab purcheses from this date
  buys = results.select { |result|
    (result[:bought][:date]).to_date == day
  }
  # for each of these purchases
  buys.each { |purchase|
    # if you can afford it
    price = purchase[:bought][:close]
    if price*3 < cash
      # subtract price from cash
      cash -= price*3
      # mark purchase as paid for
      purchase[:paid_for] = true
    else
      puts "broke :("
    end
  }
}
