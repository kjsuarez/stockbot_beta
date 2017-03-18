require 'net/http'
require 'uri'
require 'json'

class StockApiToucher  # gets stock info from various APIs

  def yahoo_multistock_day_change(symbols)
     day_change = [];

    ((symbols.count/1000)+1).times {|n|
      str = symbols[n*1000..((n+1)*1000)-1].to_s
      str.gsub!("\\n", ''); str.gsub!(" ", ''); str.gsub!(/\[\]/, ''); str.gsub!('"',''); str.gsub!(/\[|\]/,'')
      # query yahoo with each chunk
      day_change << yahoo_api_multi_stock(str)
    }

    day_change.flatten!
  end
end

def markitondemand_api_data sym
  uri = URI.parse("http://dev.markitondemand.com/MODApis/Api/v2/Quote/jsonp?symbol=#{sym}&callback=x")
  res = Net::HTTP.get_response(uri)
  res = res.body.gsub(/x\(|\)/, '')
  res = JSON.parse(res)

  res
end

def yahoo_api_multi_stock symbols
  uri = URI.parse("http://download.finance.yahoo.com/d/quotes.csv?s=#{symbols}&f=c1")
  res = Net::HTTP.get_response(uri)
  res = res.body.gsub("\n",",")
  res = res.split(",")
  res
end

def yahoo_api_single_stock sym
  uri = URI.parse("http://download.finance.yahoo.com/d/quotes.csv?s=#{sym}&f=l1c1")
  res = Net::HTTP.get_response(uri)
  res = res.body.split(',')

  res
end

def yahoo_data_single_change_percent sym
  data = yahoo_api_single_stock(sym)
  change_percent = (data[1].to_f / data[0].to_f)*100

  change_percent
end

def yahoo_api_multi_compare arry
  results = arry
  arry.each_with_index{ |data, i|
    # results[i] = {}
    stock_symbol = data[:symbol]
    # results[i][:symbol] = stock_symbol
    old_price = results[i][:old_price] = data[:price]
    responce = yahoo_api_single_stock(stock_symbol)
    new_price = results[i][:new_price] = responce[0].to_f
    change = new_price - old_price
    percent_difference = results[i][:percent_difference] = (change / old_price)*100
    if data[:price] > responce[0].to_f
      results[i][:change] = "down"
    elsif data[:price] < responce[0].to_f
      results[i][:change] = "up"
    else
      results[i][:change] = "none"
    end
  }
  winners = results.select{|data| data[:change] == "up"}
  puts "number of stocks improved since original suggestion:
        #{winners.count} out of #{arry.count}"
  puts winners.sort { |a,b| a[:percent_difference] <=> b[:percent_difference] }
end

def day_change(sym)
  uri = URI.parse("http://dev.markitondemand.com/MODApis/Api/v2/Quote/jsonp?symbol=#{sym}&callback=x")
  res = Net::HTTP.get_response(uri)
  res = res.body.gsub(/x\(|\)/, '')
  res = JSON.parse(res)
  return res['Change']
end

# uri = URI.parse("http://dev.markitondemand.com/MODApis/Api/v2/Quote/jsonp?symbol=AAPL&callback=x")
# res = Net::HTTP.get_response(uri)
# res = res.body.gsub(/x\(|\)/, '')
# res = JSON.parse(res)
# puts res['Change']
