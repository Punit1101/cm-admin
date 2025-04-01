class CmRole < ApplicationRecord
  include CmAdmin::CmRole

  has_many :cm_permissions

  validates :name, uniqueness: true, presence: true

  has_paper_trail
end
