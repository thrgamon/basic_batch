require 'pry'
require 'open-uri'

class BatchBrew
  def initialize
    Thread.current[:batch_1] = {}
    Thread.current[:loaded] = {}
    @thread_store = :batch_1
    @loaded_thread_store = :loaded
  end

  def for(block_location, key, &block)
    unless Thread.current[@thread_store][block_location]
      Thread.current[@thread_store][block_location] = {}
    end
    Thread.current[@thread_store][block_location][key] ||= block
    Resolver.new(@thread_store, @loaded_thread_store, block_location, key)
  end

end

class Resolver
  def initialize(thread_store, loaded_thread_store, block_location, key)
    @thread_store = thread_store
    @loaded_thread_store = loaded_thread_store
    @block_location = block_location
    @key = key
  end

  def resolve
    if Thread.current[@loaded_thread_store].dig(@block_location, @key)
      Thread.current[@loaded_thread_store][@block_location][@key]
    else
      Thread
        .current[@thread_store][@block_location][@key]
        .call(Thread.current[@thread_store][@block_location].keys)
        .then {|result| Thread.current[@loaded_thread_store][@block_location] = result }
        .then {|result| result[@key]}
    end
  end
end

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

bb = BatchBrew.new
ws = WeatherStation.new

def resolve(obj)
  case obj
  when Array
    obj.map! {|x| resolve(x)}
  when String
    obj
  when Resolver
    obj.resolve
  when Hash
    obj.transform_values! {|x| resolve(x) }
  end
end

t1 = Time.new
hash1 = {
  name: 'Tom',
  location: {
    city: 'Melbourne',
    weather: ws.get_weather_for_location('melbourne')
  },
  friend: [
    {
      name: 'Frank',
      location: {
        city: 'Japan',
        weather: ws.get_weather_for_location('japan')
      }
    },
    {
      name: 'Sally',
      location: {
        city: 'Manchester',
        weather: ws.get_weather_for_location('manchester')
      }
    },
    {
      name: 'Bruce',
      location: {
        city: 'Sydney',
        weather: ws.get_weather_for_location('sydney')
      }
    }
  ]
}
t2 = Time.new
puts t2 - t1

t1 = Time.new
hash2 = {
  name: 'Tom',
  location: {
    city: 'Melbourne',
    weather: bb.for(:weather, "melbourne") { |locations| ws.get_weather_for_locations(locations)}
  },
  friend: [
    {
      name: 'Frank',
      location: {
        city: 'Japan',
        weather: bb.for(:weather, "japan") { |locations| ws.get_weather_for_locations(locations)}
      }
    },
    {
      name: 'Sally',
      location: {
        city: 'Manchester',
        weather: bb.for(:weather, "manchester") { |locations| ws.get_weather_for_locations(locations)}
      }
    },
    {
      name: 'Bruce',
      location: {
        city: 'Sydney',
        weather: bb.for(:weather, "sydney") { |locations| ws.get_weather_for_locations(locations)}
      }
    }
  ]
}
resolve(hash2)
t2 = Time.new
puts t2 - t1
