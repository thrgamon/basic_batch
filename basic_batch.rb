require 'pry'
require_relative './weather_station.rb'

class ThreadStore

  attr_reader :store_name

  def initialize(store_name)
    @store_name = store_name
    Thread.current[store_name] = {}
  end
  
  def []=(key, value)
    Thread.current[store_name][key] = value
  end

  def [](key)
    Thread.current[store_name][key]
  end

  def dig(*keys)
    Thread.current[store_name].dig(*keys)
  end

end

class BatchBrew

  attr_reader :thread_store, :loaded_thread_store

  def initialize
    @thread_store = ThreadStore.new(:batch)
    @loaded_thread_store = ThreadStore.new(:loaded_batch)
  end

  def for(block_location, key, &block)
    unless thread_store[block_location]
      thread_store[block_location] = {}
    end
    thread_store[block_location][key] ||= block
    Resolver.new(thread_store, loaded_thread_store, block_location, key)
  end

end


class Resolver

  attr_reader :thread_store, :loaded_thread_store, :block_location, :key

  def initialize(thread_store, loaded_thread_store, block_location, key)
    @thread_store = thread_store
    @loaded_thread_store = loaded_thread_store
    @block_location = block_location
    @key = key
  end

  def resolve
    if loaded_thread_store.dig(block_location, key)
      loaded_thread_store[block_location][key]
    else
      thread_store[block_location][key]
        .call(thread_store[block_location].keys)
        .then {|result| loaded_thread_store[block_location] = result }
        .then {|result| result[key]}
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
pp hash2
