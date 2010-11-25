class MeetingsController < ApplicationController
  before_filter :authenticated, :except => [:index, :show]
  include MeetingsHelper
  # GET /meetings
  # GET /meetings.xml
  def index
    @meetings = nil
    @meetings_per_page = 6.0
    @page_number = {
      :current => 1,
      :set_leader => 1,
      :set_final => 1,
      :last => 1
    }
    search_conditions = []
    flag_select_from_all_organizers = show_all_meetings?
    flag_select_from_search_query = params[:q] != nil

    if flag_select_from_all_organizers
      # NOP
    else
      search_conditions_per_user = 'organizer = "' + auth_info[:user] + '"'
      search_conditions.push(search_conditions_per_user)
    end

    if flag_select_from_search_query
      # TODO need to find the way to escape the query against SQL injection
      search_query = params[:q]
      search_conditions_per_query = [
        'title LIKE "%' + search_query + '%"',
        'note LIKE "%' + search_query + '%"'
      ]
      if flag_select_from_all_organizers
        search_conditions_per_query.push('organizer LIKE "%' + search_query + '%"')
      end
      search_conditions.push("(" + search_conditions_per_query.join(' OR ') + ")")
    end

    offset = 0
    if params[:p] and params[:p].to_i > 1
      @page_number[:current] = params[:p].to_i
      offset = (@page_number[:current] - 1) * @meetings_per_page
    end

    @page_number[:last] = (Meeting.count / @meetings_per_page).ceil

    @page_number[:set_leader] = @page_number[:current] - 8
    @page_number[:set_final] = @page_number[:current] + 8
    if @page_number[:set_leader] < 1
      @page_number[:set_leader] = 1
    end
    if @page_number[:set_final] > @page_number[:last]
      @page_number[:set_final] = @page_number[:last]
    end

    if search_conditions.empty?:
      @meetings = Meeting.find(:all, :order => 'updated_at DESC', :limit => @meetings_per_page, :offset => offset)
    else
      @meetings = Meeting.find(:all, :order => 'updated_at DESC', :limit => @meetings_per_page, :offset => offset, :conditions => search_conditions.join(' AND '))
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @meetings }
    end
  end

  # GET /meetings/1
  # GET /meetings/1.xml
  def show
    @meeting = nil
    begin
      @meeting = Meeting.find(params[:id])
    rescue
      render "e404", :layout => "meetings", :status => 404
      return
    end

    if @meeting.nil?
      render "e404", :layout => "meetings", :status => 404
    end

    if params[:key]
      key_register @meeting.id, params[:key]
    end

    if params[:pid] and params[:response]
      @active_participant = @meeting.participants.find(params[:pid])
      if key_hash(@active_participant.email) != params[:response]
        @active_participant = nil
      elsif @active_participant.status == 0
        @active_participant.status = 1
      end
    else
      @active_participant = nil
    end

    auto_set_status

    if not accessible?(@meeting)
      render "e401", :layout => "meetings", :status => 401
    else
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @meeting }
      end
    end
  end

  # GET /meetings/new
  # GET /meetings/new.xml
  def new
    @meeting = Meeting.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @meeting }
    end
  end

  # GET /meetings/1/edit
  def edit
    @meeting = Meeting.find(params[:id])
  end

  # POST /meetings
  # POST /meetings.xml
  def create
    @meeting = Meeting.new(params[:meeting])

    if @meeting.start > @meeting.finish
      @meeting.finish = @meeting.start
    end

    respond_to do |format|
      if @meeting.save
        clean_up_data
        format.html { redirect_to(@meeting, :notice => '<p>You just added a new meeting.</p>') }
        format.xml  { render :xml => @meeting, :status => :created, :location => @meeting }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @meeting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /meetings/1
  # PUT /meetings/1.xml
  def update
    @meeting = Meeting.find(params[:id])
    if params[:do_notify] and params[:do_notify] == "on"
      send_update
    end

    respond_to do |format|
      if @meeting.update_attributes(params[:meeting])
        clean_up_data
        format.html { redirect_to(@meeting, :notice => '<p>Successfully updated.</p>') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @meeting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /meetings/1
  # DELETE /meetings/1.xml
  def destroy
    @meeting = Meeting.find(params[:id])
    @meeting.destroy

    respond_to do |format|
      format.html { redirect_to(meetings_url) }
      format.xml  { head :ok }
    end
  end

  private

  def auto_set_status
    if meeting_state(@meeting) < 2 and @meeting.status >= 3
      @meeting.status = 2
      @meeting.save
    elsif meeting_state(@meeting) == 2 and @meeting.status < 3
      @meeting.status = 4
      @meeting.save
    elsif meeting_state(@meeting) == 3 and @meeting.status < 6
      @meeting.status = 8
      @meeting.save
    end
  end

  def clean_up_data
    @meeting.title = @meeting.title.strip
    @meeting.organizer = @meeting.organizer.strip
    @meeting.key = @meeting.key.strip
    if params[:tz_offset]
      tz_offset = params[:tz_offset].to_i
      @meeting.start = @meeting.start + tz_offset * 3600;
      @meeting.finish = @meeting.finish + tz_offset * 3600;
    end
    if @meeting.start > @meeting.finish
      @meeting.finish = @meeting.start
    end
    @meeting.save
  end

  def authenticated
    if not auth_valid?
      redirect_to '/'
    end
  end

  def send_update
    if is_stable_release?
      meeting_url = url_for :controller => :meetings, :action => :show, :id => @meeting.id, :only_path => false
      meeting_url += "?key=" + key_hash(@meeting.key)
      @meeting.participants.each { |participant|
        if participant.status < 4
          Notifier.deliver_invitation_confirm auth_info, @meeting, participant, meeting_url, key_hash(participant.email)
        end
      }
    end
  end
end
