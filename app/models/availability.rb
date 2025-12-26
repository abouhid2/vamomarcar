class Availability < ApplicationRecord
  belongs_to :user
  belongs_to :group

  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :for_group, ->(group) { where(group: group) }
  scope :for_user, ->(user) { where(user: user) }

  def date_range
    (start_date..end_date).to_a
  end

  def single_day?
    start_date == end_date
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after or equal to start date")
    end
  end
end
