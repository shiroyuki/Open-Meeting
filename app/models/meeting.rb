class Meeting < ActiveRecord::Base
  validates_presence_of :title
  has_many :participants
end
