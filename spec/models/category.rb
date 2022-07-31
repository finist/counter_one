class Category < ActiveRecord::Base

  has_many :category_users
  has_many :users, through: :category_users

end
