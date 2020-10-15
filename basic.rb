require_relative './weather_station.rb'

def resolve(obj)
  case obj
  when Array
    obj.map! {|x| resolve(x)}
  when String
    obj
  when Proc
    obj.call
  when Hash
    obj.transform_values! {|x| resolve(x) }
  end
end

ws = WeatherStation.new

hash1 = {
  name: 'Tom',
  location: {
    city: 'Melbourne',
    weather: -> () {ws.get_weather_for_location('melbourne')}
  },
  friend: [
    {
      name: 'Frank',
      location: {
        city: 'Japan',
        weather: -> () {ws.get_weather_for_location('japan')}
      }
    },
    {
      name: 'Sally',
      location: {
        city: 'Manchester',
        weather: -> {ws.get_weather_for_location('manchester')}
      }
    },
    {
      name: 'Bruce',
      location: {
        city: 'Sydney',
        weather: -> {ws.get_weather_for_location('sydney')}
      }
    }
  ]
}
t1 = Time.new
resolve(hash1)
t2 = Time.new

puts t2 - t1
pp hash1
