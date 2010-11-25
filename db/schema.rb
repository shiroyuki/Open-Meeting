# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100604180900) do

  create_table "meetings", :force => true do |t|
    t.string   "title"
    t.string   "organizer"
    t.datetime "start"
    t.datetime "finish"
    t.text     "note"
    t.integer  "status"
    t.string   "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "participants", :force => true do |t|
    t.integer  "meeting_id"
    t.string   "name"
    t.string   "email"
    t.text     "note"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
