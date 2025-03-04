class Part < ActiveRecord::Base
  belongs_to :product
  has_many :options, dependent: :destroy
  has_many :part_variants, dependent: :destroy

  validates :part_key, :name, presence: true
  validates :part_key, uniqueness: { scope: :product_id }
end
