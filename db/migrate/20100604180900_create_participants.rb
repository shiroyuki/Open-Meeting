class CreateParticipants < ActiveRecord::Migration
  def self.up
    create_table :participants do |t|
      t.integer :meeting_id
      t.string :name
      t.string :email
      t.text :note
      t.integer :status

      t.timestamps
    end
  end

  def self.down
    drop_table :participants
  end
end
