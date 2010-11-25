class Participant < ActiveRecord::Base
  validates_presence_of :name, :email
  belongs_to :meetings
end
