class Group < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :availabilities, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :is_public, inclusion: { in: [ true, false ] }
  validates :weekends_only, inclusion: { in: [ true, false ] }

  before_create :generate_invitation_token, if: :needs_invitation_token?
  after_create :add_owner_as_member

  def all_users
    members.or(User.where(id: owner_id)).distinct
  end

  def generate_invitation_token
    self.invitation_token = loop do
      token = SecureRandom.urlsafe_base64(24)
      break token unless Group.exists?(invitation_token: token)
    end
  end

  def regenerate_invitation_token!
    generate_invitation_token
    save!
  end

  def invitation_url(base_url)
    return nil unless invitation_token.present?
    "#{base_url}/groups/#{id}/join?token=#{invitation_token}"
  end

  def enable_invitations!
    generate_invitation_token unless invitation_token.present?
    update!(invitation_enabled: true)
  end

  def disable_invitations!
    update!(invitation_enabled: false)
  end

  def member?(user)
    all_users.include?(user)
  end

  private

  def add_owner_as_member
    group_memberships.create(user: owner) unless group_memberships.exists?(user: owner)
  end

  def needs_invitation_token?
    !is_public && invitation_token.blank?
  end
end
