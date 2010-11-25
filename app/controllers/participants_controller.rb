class ParticipantsController < ApplicationController
  before_filter :defend_if_stable_release, :except => [:update, :create, :destroy]
  
  # GET /participants
  # GET /participants.xml
  def index
    @participants = Participant.all

    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @participants }
    end
  end

  # GET /participants/1
  # GET /participants/1.xml
  def show
    #head :status => 405
    #return
    
    @participant = Participant.find(params[:id])
    
    # debugging
    #@meeting = Meeting.find(@participant.meeting_id)
    #send_invitation

    respond_to do |format|
      format.html # show.html.erb
      #format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/new
  # GET /participants/new.xml
  def new
    head :status => 405
    return
    
    @participant = Participant.new

    respond_to do |format|
      format.html # new.html.erb
      #format.xml  { render :xml => @participant }
    end
  end

  # GET /participants/1/edit
  def edit
    #head :status => 405
    #return
    
    @participant = Participant.find(params[:id])
  end

  # PUT /participants/1
  # PUT /participants/1.xml
  def update
    @participant = Participant.find(params[:id])
    @notice = nil
    respond_to do |format|
      if @participant.update_attributes(params[:participant])
        format.html { redirect_to(@participant, :notice => 'Participant was successfully updated.') }
        #format.xml  { head :ok }
        format.js
      else
        @notice = "Cannot update your status at thte moment"
        format.html { render :action => "edit" }
        #format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  def create
    @meeting = Meeting.find(params[:meeting_id])

    params[:participant][:name] = params[:participant][:name].strip
    params[:participant][:email] = params[:participant][:email].strip
    params[:participant][:status] = 0

    if !@meeting.participants.find(:all, :conditions => {:meeting_id => @meeting.id, :email => params[:participant][:email]}).empty?
      @participant = nil
      @notice = 'Already sent the invitation to ' + params[:participant][:email]
    elsif !email_valid? params[:participant][:email]
      @participant = nil
      @notice = 'Email is invalid.'
    else
      @participant = @meeting.participants.create!(params[:participant])
      @meeting_url = send_invitation
      @notice = 'Just sent the invitation'
    end
    
    respond_to do |format|
      format.html {redirect_to @meeting, :notice => @notice}
      format.js
    end
  end

  def destroy
    begin
      @meeting = Meeting.find(params[:meeting_id])
      @participant = @meeting.participants.find(params[:id])
    rescue
      @participant = Participant.find(params[:id])
      @meeting = Meeting.find(@participant.meeting_id)
    end

    @participant.destroy

    respond_to do |format|
      #format.html { redirect_to(participants_url) }
      format.html { redirect_to @meeting }
      #format.xml  { head :ok }
      format.js
    end
  end

  private

  def defend_if_stable_release
    if is_stable_release?
      head :status => 405
      return
    end
  end

  def send_invitation
    meeting_url = url_for :controller => :meetings, :action => :show, :id => @meeting.id, :only_path => false
    meeting_url += "?key=" + key_hash(@meeting.key)
    if is_stable_release?
      Notifier.deliver_invitation_init auth_info, @meeting, @participant, meeting_url, key_hash(@participant.email)
    else
      meeting_url += "&pid=" + @participant.id.to_s + "&response=" + key_hash(@participant.email)
    end
    return meeting_url
  end
end
