require 'rest-client'


loop do
#   sleep 1
#   st = Time.now.to_f
#   RestClient.get 'http://www.posterous.com'
#   et = Time.now.to_f
#   data = et - st
#   RestClient.post 'http://localhost:8080/api/log', { :name => 'posterous_load_2', :data => data }
  RestClient.post 'http://localhost:8080/api/log', { :name => 'test_func', :data => rand(100) }
end
