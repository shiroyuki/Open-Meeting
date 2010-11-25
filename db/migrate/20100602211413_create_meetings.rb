class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.string :title
      t.string :organizer
      t.datetime :start
      t.datetime :finish
      t.text :note
      t.integer :status
      t.string :key

      t.timestamps
    end
  end

  def self.down
    drop_table :meetings
  end
end
