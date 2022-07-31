# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120522160158) do

  create_table "users", :force => true do |t|
    t.boolean  "approved", default: false
    t.integer  "products_count", default: 0
    t.integer  "approved_products_count", default: 0
    t.integer  "comments_count", default: 0
    t.integer  "approved_comments_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "products", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.boolean  "approved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "comments", :force => true do |t|
    t.string   "body"
    t.integer  "product_id"
    t.boolean  "approved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "approved_users_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "category_users", :force => true do |t|
    t.integer   "category_id"
    t.integer   "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
