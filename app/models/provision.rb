class Provision < ApplicationRecord
  has_many :events, dependent: :destroy
end
