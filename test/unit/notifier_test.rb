require 'test_helper'

class NotifierTest < ActionMailer::TestCase
  test "invitation_init" do
    @expected.subject = 'Notifier#invitation_init'
    @expected.body    = read_fixture('invitation_init')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_invitation_init(@expected.date).encoded
  end

  test "invitation_confirm" do
    @expected.subject = 'Notifier#invitation_confirm'
    @expected.body    = read_fixture('invitation_confirm')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_invitation_confirm(@expected.date).encoded
  end

end
