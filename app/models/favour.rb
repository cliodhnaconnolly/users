class Favour < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  validates :user_id, presence: true
  validates :title, presence: true
  validates :deadline, presence: true
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode  # auto-fetch address
  geocoded_by :address
  after_validation :geocode,
                   :if => lambda{ |obj| obj.latitude.nil? }
end
