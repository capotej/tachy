require 'rest-client'


loop do
  st = Time.now.to_f
  RestClient.post 'http://localhost:8080/log', { :name => 'test_func', :data => rand(112312312) }
  et = Time.now.to_f
  puts st.to_f - et.to_f
end
