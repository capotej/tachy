require 'bundler'
Bundler.require
require 'cgi'
require 'json'

WINDOW_SIZE = 1000

class TachyServer < EM::Connection
  include EM::HttpServer
  
  def post_init
    super
    no_environment_strings
  end
  
  def process_http_request
    # the http request details are available via the following instance variables:
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_headers
    puts "#{Time.now.to_f} accessing #{@http_request_uri}"
    if @http_request_uri == "/api/log"
      params = CGI.parse(@http_post_content)
      $redis.sadd('tachy_lists', params["name"][0])
      $redis.lpush(params["name"][0], "#{Time.now.to_f}:#{params["data"][0]}")
      $redis.ltrim(params["name"][0], 0, WINDOW_SIZE)
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/plain'
      response.content = 'OK'
      response.send_response
    end
    if @http_request_uri == "/api/funcs"
      $redis.smembers('tachy_lists') do |members|
        response = EM::DelegatedHttpResponse.new(self)
        response.status = 200
        response.content_type 'application/json'
        response.content = members.to_json
        response.send_response
      end
    end
    if @http_request_uri.include?("/api/view")
      func_name = @http_request_uri.split("/").last.gsub('/','')
      $redis.lrange(func_name, 0, WINDOW_SIZE) do |range|
        response = EM::DelegatedHttpResponse.new(self)
        response.status = 200
        response.content_type 'application/json'
        response.content = range.to_json
        response.send_response
      end
    end
    if @http_request_uri == "/dashboard"
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      response.content = File.read('index.html')
      response.send_response
    end


  end
end

EM.run{
  $redis = EM::Protocols::Redis.connect
  EM.start_server '0.0.0.0', 8080, TachyServer
}
