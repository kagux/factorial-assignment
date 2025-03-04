class Product < ActiveRecord::Base
  has_many :parts, dependent: :destroy
  has_many :product_builds, dependent: :destroy

  validates :name, :product_key, presence: true
  validates :product_key, uniqueness: true
end