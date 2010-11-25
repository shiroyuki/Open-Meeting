class MainController < ApplicationController
  layout "main"
  
  def index
  end

  def about
  end

  def privacy
  end

  def terms
  end

  def how_it_works
  end

  def e404
    render "e404", :layout => "main", :status => 404
    return
  end

end
