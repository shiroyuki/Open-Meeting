module ParticipantsHelper
  def participant_status_label(status_code, fix_grammar_as_verb = false)
    status_code = status_code.to_i
    status_labels = [
      'Invited', #0
      'Attended',
      'Probably attended',
      'Not attended',
      'Ignored (and received no further updates)' #4
    ]

    return_status = status_labels[status_code]
    if fix_grammar_as_verb 
      if (status_code == 0 or status_code == 4)
        return_status = return_status.gsub /d$/, ''
      else
        return_status = return_status.gsub /ed$/, ''
      end
    end

    return return_status
  end
end
