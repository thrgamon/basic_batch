require 'pry'
require 'open-uri'
require_relative './weather_station.rb'

class BatchBrew
  def initialize
    Thread.current[:batch] = {}
    Thread.current[:loaded] = {}
    @thread_store = :batch
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

bb = BatchBrew.new
ws = WeatherStation.new

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

t1 = Time.new
resolve(hash2)
t2 = Time.new

puts t2 - t1
