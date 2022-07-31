class User < ActiveRecord::Base

  has_many :products
  
  has_many :category_users
  has_many :categories, through: :category_users

end
