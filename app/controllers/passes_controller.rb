class PassesController < ApplicationController
  layout 'main'
  protect_from_forgery :except => :checkin
  
  def checkin
    @status = "Unauthorized"
    @reason = ""
    @label = "Try again"
    @link = "/"
    if auth_valid?
      @status = "Authorized"
      @reason = "You are already signed in."
      @label = "Go back"
      @link = "/meetings"
    elsif params[:username] and params[:password]
      if auth_request params[:username], params[:password]
        @status = "Authorized"
        @reason = "Successfully signed in."
        @label = "Get started"
        @link = "/meetings"
        render :layout => 'main', :status => 200
      else
        @reason = "Incorrect information"
        render :layout => 'main', :status => 401
      end
    elsif params[:oauth] == "use_twitter"
      twitter_oauth_init
      @status = "Connection via Twitter"
      @reason = "You can sign into Open Meeting with your Twitter account.<br/>Please note that Open Meeting does only request read-only permission at this time."
      @label = "Proceed"
      @link = session[:oauth_r].authorize_url
      redirect_to session[:oauth_r].authorize_url
    elsif params[:oauth] == "twitter" and params[:oauth_verifier]
      if twitter_oauth_authorize :oauth_verifier => params[:oauth_verifier]
        @status = "Connected with Twitter"
        @reason = "You are now using Open Meeting under your Twitter account."
        @label = "Get started"
        @link = "/meetings"
      else
        @status = "Failed to sign in"
        @reason = "Open Meeting could not connect the session with Twitter."
        @label = "Go to top page"
        @link = "/"
        render :layout => 'main', :status => 401
      end
    else
      @reason = "Insufficient information"
      render :layout => 'main', :status => 400
    end

  end

  def validate
    @status = "invalid"
    if auth_valid?
      @status = "valid"
      render :layout => 'main', :status => 200
    elsif auth_valid_with_twitter?
      @status = "valid (via Twitter)"
      render :layout => 'main', :status => 200
    else
      render :layout => 'main', :status => 404
    end
  end

  def checkout
    auth_revoke
  end
end