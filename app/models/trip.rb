class Trip < ActiveRecord::Base
  belongs_to :shopper, class_name: 'User'
  has_many :requests
  has_one :location, through: :shopper

  enum status: [:active, :not_accepting_requests, :ended]

  scope :not_ended, -> { where.not(status: Trip.statuses[:ended]) }
end
