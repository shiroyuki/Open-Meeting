module MeetingsHelper
  include ParticipantsHelper
  def own?(meeting)
    if not auth_valid?
      return false
    end
    user_alias = auth_info[:user]
    if user_alias.nil?
      return false
    end
    return meeting.organizer == user_alias
  end

  def protected?(meeting)
    if meeting.key.strip.empty?
      return false
    end
    return true
  end

  def has_authorized_key?(meeting)
    if not auth_valid? and params[:key].nil?
      return false
    elsif not auth_valid?
      return key_match?(meeting.key, params[:key])
    end
    return key_match?(meeting.key, auth_info[:key_chain][meeting.id])
  end

  def accessible?(meeting)
    if own?(meeting) or !protected?(meeting) or has_authorized_key?(meeting)
      return true
    elsif params[:key] and key_match?(meeting.key, params[:key])
      return true
    end
    return false
  end

  def access_with_invitation?
    return !@active_participant.nil?
  end

  def get_secure_url
    url = url_for :controller => :meetings, :action => :show, :id => @meeting.id, :only_path => false
    url += "?key=" + key_hash(@meeting.key)
    return url
  end

  def get_status_label(status_code)
    status_labels = [
      'Pending',
      'Open registration', #1
      'Close registration',
      'Accessible without invitation', #3
      'Authorized access only',
      'Additional accesses forbidden',
      'Postponed', #6
      'Cancelled',
      'Inactive'
    ]

    return status_labels[status_code]
  end

  def show_all_meetings?
    if !auth_valid? or (params[:all] and params[:all] == 1)
      return true
    end
    return false
  end

  def get_window_title
    ret = ''
    if controller.action_name == "index"
      if show_all_meetings?
        ret = "All meetings"
      else
        ret = "All meetings organized by you"
      end
    elsif controller.action_name == "show"
      ret = "Meeting information"
    else
      ret = controller.action_name.capitalize + " meeting"
    end

    ret
  end

  def get_meeting_when(meeting)
    ret_time = ''
    
    if meeting.start == meeting.finish
      ret_time = '<span class="datetime">' + get_time_format(meeting.start) + '</span>'
    else
      ret_time = '<span class="datetime">' + get_time_format(meeting.start) + '</span> - <span class="datetime">' + get_time_format(meeting.finish) + '</span>'
    end
    return ret_time
  end

  def get_time_format(time_obj, use_local=false, easy_format=false)
    time_x = time_obj.utc
    if use_local
      time_x = time_obj.getlocal
    end
    time_fmt = "%A, %d %B %Y %H:%M %Z"
    if easy_format
      time_fmt = "%Y.%m.%d %H:%M %Z"
    end
    return time_x.strftime(time_fmt)
  end

  def meeting_registrable?(meeting)
    if meeting.status == 1 or meeting.status == 3
      return true
    end
    return false
  end

  def meeting_state(meeting)
    if meeting.status >= 6
      return 3 # end
    elsif meeting.status == 0
      return 0 # not starting
    end

    time_x = Time.new.utc
    tl = get_time_length time_x, meeting.start, [:day]
    td = get_time_difference time_x, meeting.start

    if time_x < meeting.start and td[:d] == 0 and td[:h] == 0 and td[:m] <= 15 # 15 minutes before starting
      tl = 1 # about to start
    elsif tl.empty?
      if time_x > meeting.start and time_x < meeting.finish
        tl = 2 # on going
      else # if time_b < time_a
        tl = 3 # done
      end
    else
      tl = 0 # not starting
    end

    return tl
  end

  def get_time_status(meeting)
    tl = ''

    mstate = meeting_state meeting

    if meeting.status == 0
      tl = "Pending"
    elsif mstate == 0
      tl = get_time_length :now, meeting.start, [:day]
      tl = "Countdown: " + tl
    elsif mstate == 1
      tl = "About to start"
    elsif mstate == 2
      tl = "Now"
    else
      tl = "Done"
    end

    return tl
  end

  def get_time_duration(meeting)
    starting_time = meeting.start
    in_progress = (meeting.start < Time.new.utc)

    if in_progress
      starting_time = Time.new.utc
    end

    tl = get_time_length starting_time, meeting.finish

    if tl.empty?
      tl = "unknown"
    else
      tl = tl
    end

    if in_progress
      tl += " remaining"
    end

    tl
  end

  def get_time_length(time_a, time_b, show_only=[])
    if show_only.empty?
      show_only.push :day, :hour, :minute, :second
    end

    tl = []

    td = get_time_difference time_a, time_b
    
    if td[:s] < 0
      td[:s] = 0
      show_only = []
    else
      if td[:d] > 0 and show_only.include? :day
        tl.push get_unit(td[:d], "day", "days")
      else
        show_only.push :hour
      end

      if td[:h] > 0 and show_only.include? :hour
        tl.push get_unit(td[:h], "hour", "hours")
      else
        show_only.push :minute
      end

      if td[:m] > 0 and show_only.include? :minute
        tl.push get_unit(td[:m], "minute", "minutes")
      end

      if td[:s] > 0 and show_only.include? :second
        tl.push get_unit(td[:s], "second", "seconds")
      end
    end

    return tl.join(' ')
  end

  def get_time_difference(time_a, time_b)
    td = {
      :d => 0,
      :h => 0,
      :m => 0,
      :s => 0
    }

    if time_a == :now
      time_a = Time.new
    end

    td[:s] = time_b.utc - time_a.utc
    td[:s] = td[:s].to_i

    if td[:s] < 0
      td[:s] = 0
    else
      td[:m] = td[:s] / 60
      td[:s] = td[:s] - td[:m] * 60

      td[:h] = td[:m] / 60
      td[:m] = td[:m] - td[:h] * 60

      td[:d] = td[:h] / 24
      td[:h] = td[:h] - td[:d] * 24
    end

    return td
  end

  def get_unit(number, singular_form, plural_form)
    unit = plural_form
    if number == 1 or (number < 1 and number > 0)
      unit = singular_form
    end

    "#{number} #{unit}"
  end
end
