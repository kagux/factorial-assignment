class Option < ActiveRecord::Base
  belongs_to :part
  has_many :option_values, dependent: :destroy

  validates :option_key, :name, presence: true
  validates :option_key, uniqueness: { scope: :part_id }
end
