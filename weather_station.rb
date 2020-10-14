class WeatherStation
  def get_weather_for_location(location)
    puts "Launching weather balloon"
    sleep(1)
    puts "Triangulating longitude"
    sleep(1)
    puts "Looking up how to spell cumulonimbus"
    sleep(1)
    open("http://wttr.in/#{location}?format=3").read.strip 
  end

  def get_weather_for_locations(locations)
    puts "Launching weather balloons"
    sleep(1)
    puts "Triangulating longitudes"
    sleep(1)
    puts "Looking up how to spell cumulonimbus"
    sleep(1)
    weathers = locations.map do |location|
      Thread.new { [location, open("http://wttr.in/#{location}?format=3").read.strip] }
    end

    weathers.map {|weather| weather.join.value }.to_h
  end
end
