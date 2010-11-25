class Notifier < ActionMailer::Base
  include SecurityInterface

  def invitation_init(organizer, meeting, participant, meeting_url, response_id, sent_at = Time.now)
    content_type 'text/html; charset=utf-8'
    subject    'Invitation for "' + meeting.title + '" on Open Meeting'
    recipients participant.email
    from       sender
    sent_on    sent_at
    
    body       :organizer => organizer, :meeting => meeting, :participant => participant, :meeting_url => meeting_url, :response_id => response_id
  end

  def invitation_confirm(organizer, meeting, participant, meeting_url, response_id, sent_at = Time.now)
    content_type 'text/html; charset=utf-8'
    subject    '[Updated] Open Meeting: ' + meeting.title
    recipients participant.email
    from       sender
    sent_on    sent_at

    body       :organizer => organizer, :meeting => meeting, :participant => participant, :meeting_url => meeting_url, :response_id => response_id
  end

  private

  def sender
    'jnopporn@tamako.local'
  end
end
