require 'digest/sha2'
require 'net/http'
require 'net/smtp'
require 'uri'
require 'oauth'
require 'json'

module SecurityInterface
  include ControlInterface
  
  # Check if this is the stable release
  def is_stable_release?
    test_subject = url_for :controller => 'Passes', :action => 'checkin', :only_path => false
    return !test_subject.match(/om\.shiroyuki\.com/).nil?
  end

  # Generate the hash key
  def key_hash(key)
    ekey = Digest::SHA512.hexdigest(key.to_s)
    return ekey[0..20] + ekey[99..128]
  end

  # Register the encrypted key to the user session
  def key_register(id, encrypted_key)
    if auth_valid? and not encrypted_key.nil?
      auth_info[:key_chain][id] = encrypted_key
    end
  end

  # Compare keys
  def key_match?(key, encrypted_key)
    if encrypted_key.nil?
      return false
    end
    return key_hash(key) == encrypted_key
  end

  # Check if the given email is valid
  def email_valid?(email)
    rx = /^[^ \@]+\@[^ \@]+\.\w+$/
    rt = email.strip().match rx
    return !rt.nil?
  end

  # Make HTTP request
  def http_send(method, dest, params = {})
    res = nil
    begin
      if method == "get"
        url = URI.parse(dest)
        req = Net::HTTP::Get.new(url.path)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
      elsif method == "post"
        res = Net::HTTP.post_form(URI.parse(dest), params)
      end
    rescue
      # do nothing
    end

    return res
  end

  # Extract the HTTP responding code
  def http_code(res)
    begin
      return Integer res.code
    rescue
      return 500
    end
  end

  # Check if the HTTP response is ok
  def http_ok?(res)
    begin
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return true
      else
        return false
      end
    rescue
      return false
    end
  end

  # Get the URL to OZ root service
  def get_path_to_oz(path='')
    server = 'http://127.0.0.1:8080/oz'
    path = path.strip
    if path
      if path[0] != '/'
        server += '/'
      end
      server += path
    end
    return server
  end

  # Get the URL to OZ OpenID service
  def get_auth_api_server
    return get_path_to_oz 'api/passes'
  end

  def auth_init
    session[:auth] = nil
  end
  
  def auth_info(replace_info={})
    if not replace_info.empty?
      session[:auth] = {
        :provider => replace_info[:provider],
        :alias => replace_info[:alias],
        :user => replace_info[:user],
        :key => replace_info[:key],
        :key_chain => {},
        :ip => request.remote_addr
      }

      if session[:auth][:provider] == "twitter"
        session[:auth][:user] = '@' + replace_info[:user]
      end
    end
    return session[:auth]
  end

  # Check if the user session is authorized
  def auth_info?
    return session.has_key? :auth
  end

  # Check if the user's authorization is valid
  def auth_valid?
    authorized = false
    settings = get_settings
    # Validate the session
    puts settings
    if settings["security"]["authorize_everyone"]
      auth_info :user => "guest", :alias => "guest", :provider => 'OZ'
      authorized = true
    elsif auth_info
      authorized = true
      if (auth_info[:ip] != request.remote_addr) or (!auth_valid_with_twitter? and !auth_validate(auth_info[:user], auth_info[:key])) or (auth_info[:user] == "public_user")
        authorized = false
        auth_revoke
      end
    end

    return authorized
  end

  # Check if the user key is the same as the given one.
  def auth_validate(username, key)
    uri_to_auth_api = "#{get_auth_api_server}/#{username}/#{key}"
    res = http_send "get", uri_to_auth_api
    if http_code(res) == 504 # Gateway timeout
      raise res.body
    end
    return http_ok? res
  end

  # Check if the session is authorized with Twitter ID
  def auth_valid_with_twitter?
    begin
      return auth_info[:provider] == "twitter"
    rescue
      return false
    end
  end

  # Send a request for the authorization
  def auth_request(username, password, domain=nil)
    uri_to_auth_api = get_auth_api_server
    params_for_api = {'username'=>username, 'password'=>password}
    if domain
      params_for_api[:domain] = domain
    end
    res = http_send "post", uri_to_auth_api, params_for_api
    if http_ok? res
      data = JSON.parse(res.body)
      auth_info :user => data['user'], :key => data['key']
    else
      res = nil
    end
    return res
  end

  # Revoke the authorization
  def auth_revoke
    oauth_revoke
    auth_init
  end

  # Revoke OAuth information
  def oauth_revoke
    session[:oauth_a] = nil
    session[:oauth_r] = nil
  end

  def twitter_get_home(user=nil)
    server = "http://twitter.com/"
    if user
      user = user.gsub(/^\@/, '')
      server += user
    end
    return server
  end

  def twitter_get_api_oauth
    return "https://api.twitter.com"
  end

  def twitter_get_api_oauth_cb
    url = url_for :controller => 'Passes', :action => 'checkin', :only_path => false
    url += "?oauth=twitter"
    return url
  end

  def twitter_oauth_consumer# the default value is for development
    oauth = {
      :key => "Consumer key",
      :secret => "Consumer secret"
    }

    if is_stable_release?
      oauth = {
        :key => "Consumer key",
        :secret => "Consumer secret"
      }
    end

    consumer = OAuth::Consumer.new(
      oauth[:key], # Key
      oauth[:secret], # Secret
      {
        :site => twitter_get_api_oauth
      }
    )
    return consumer
  end

  def twitter_oauth_init
    consumer = twitter_oauth_consumer
    request_token = consumer.get_request_token :oauth_callback => twitter_get_api_oauth_cb
    session[:oauth_r] = request_token
  end

  def twitter_oauth_access(options={})
    consumer = twitter_oauth_consumer
    request_token = OAuth::RequestToken.new(
      consumer, session[:oauth_r].token, session[:oauth_r].secret
    )
    access_token = request_token.get_access_token options

    access_token
  end

  def twitter_oauth_authorize(options={})
    access_token = twitter_oauth_access options
    
    oauth_response = access_token.get('/1/statuses/user_timeline.json?count=1')
    data = JSON.parse(oauth_response.body)
    #raise oauth_response.body
    
    auth_info :user => data[0]['user']['screen_name'].to_s, :alias => data[0]['user']['name'].to_s, :provider => 'twitter'
  end
end
