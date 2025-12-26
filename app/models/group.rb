class Group < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :availabilities, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :is_public, inclusion: { in: [ true, false ] }
  validates :weekends_only, inclusion: { in: [ true, false ] }

  after_create :add_owner_as_member

  def all_users
    members.or(User.where(id: owner_id)).distinct
  end

  private

  def add_owner_as_member
    group_memberships.create(user: owner) unless group_memberships.exists?(user: owner)
  end
end
