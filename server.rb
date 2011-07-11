require 'bundler'
Bundler.require
require 'cgi'

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
    if @http_request_uri == "/log"
      params = CGI.parse(@http_post_content)
      p params["name"]
      $redis.lpush(params["name"][0], "#{Time.now.to_f}:#{params["data"][0]}")
      $redis.ltrim(params["name"][0], 0, 100_000)
    end

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/plain'
    response.content = 'OK'
    response.send_response
  end
end

EM.run{
  $redis = EM::Protocols::Redis.connect
  EM.start_server '0.0.0.0', 8080, TachyServer
}
