require 'net/http'
require 'uri'
require 'json'
require 'linefit'

def data_is_clean?(res)
  !res.body.include?("Symbol Not Found") &&
  !res.body.include?("Data Not Found") &&
  !res.body.include?("Not Logged In") &&
  !res.body.include?("Bad Request")
end

def yearly_data_is_clean?(res)
  res.body.length > 500
end

def data_is_mature?(arry, years=5)
  arry.count >= mature_age(years)
end

def mature_age(years)
  ((((years*365)*(5.0/7.0)) - (9*years)).to_i)-2
end

def clean_data_array(res)
  # split data on line breaks
  arry = res.body.split(/\r\n/)
  # each element of arry split on ','
  arry.each_index {|x| arry[x] = arry[x].split(',')}
  return arry
end

def kibot_login
  #login to kibot as guest
    uri = URI.parse("http://api.kibot.com/?action=login&user=guest&password=guest")
    res = Net::HTTP.get_response(uri)
    puts res.body
    puts "pauseing..."
    sleep(2)
end

def last_x_days_slope(sym, days)

  arry = x_days_data(sym, days)

  if arry.is_a? Array
    # build xy arrays based on arry
    x = []; arry.length.times {|count| x[count] = count}
    y = []; arry.each_index {|indx| y[indx] = arry[indx][1].to_f}

    # get line of best fit
    lineFit = LineFit.new
    lineFit.setData(x,y)
    intercept, slope = lineFit.coefficients
    puts "slope: #{slope}, y intercept: #{intercept}"
    return {symbol: sym, slope: lineFit.coefficients[1], intercept: lineFit.coefficients[0]}
  else
    puts "immature stock"
    return {symbol: sym, slope: 0, intercept: 0}
  end

end

def last_year_slope_multiple(data_arry)
  count = data_arry.count
  slope_arry = []

  puts "kibot login"
  kibot_login

  count.times { |i|
    p "#{i}/#{count}"
    data = last_x_days_slope(data_arry[i][:symbol], 365)
    data_arry[i][:year_slope] = data[:slope]
  }
  data_arry
end

def last_month_slope_multiple(data_arry)
  count = data_arry.count
  slope_arry = []

  puts "kibot login"
  kibot_login

  count.times { |i|
    p "#{i}/#{count}"
    data = last_x_days_slope(data_arry[i][:symbol], 30)
    data_arry[i][:month_slope] = data[:slope]
  }
  data_arry
end

def x_days_data(sym, days)

  # get naked data
  uri = URI.parse("http://api.kibot.com/?action=history&symbol=#{sym}&interval=daily&period=#{days}")
  res = Net::HTTP.get_response(uri)

  # check that data is legit
  if data_is_clean?(res)

    arry = clean_data_array(res)

    if arry.count >= mature_age(days/365.0)
      return arry
    else
      puts "immature stock: #{mature_age(days/365.0)} vs. #{arry.count}"
      return {symbol: sym, slope: 0, intercept: 0}
    end
  else
    puts "bad data"
    return {symbol: sym, slope: 0, intercept: 0}
  end
end

def x_years_data(sym, years)

  # get naked data
  uri = URI.parse("http://api.kibot.com/?action=history&symbol=#{sym}&interval=daily&period=#{years*365}")
  res = Net::HTTP.get_response(uri)

  # check that data is legit
  if data_is_clean?(res)

    arry = clean_data_array(res)

    if arry.count >= mature_age(years)
      return arry
    else
      puts "immature stock: #{mature_age(years)} vs. #{arry.count}"
      return {symbol: sym, slope: 0, intercept: 0}
    end
  else
    puts "bad data"
    return {symbol: sym, slope: 0, intercept: 0}
  end
end

def slope_of_data(data_arry)
  x = []; data_arry.length.times {|count| x[count] = count}
  y = []; data_arry.each_index {|indx| y[indx] = data_arry[indx][1].to_f}

  # get line of best fit
  lineFit = LineFit.new
  lineFit.setData(x,y)
  intercept, slope = lineFit.coefficients
  return slope
end

def erratic?(data_arry, relevant_period, tolerance)
  jolts = []
  (data_arry.count-relevant_period).times{|i|
     slope = slope_of_data(data_arry[i..(i+relevant_period)])
    if slope.abs > tolerance
      jolts << data_arry[i][0]
    end
  }
  jolts.any?
end
