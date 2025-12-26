class AvailabilityCreator
  attr_reader :user, :group, :start_date, :end_date, :availability, :errors

  def initialize(user:, group:, start_date:, end_date:)
    @user = user
    @group = group
    @start_date = start_date
    @end_date = end_date
    @errors = []
  end

  def call
    return false unless valid_dates?

    ActiveRecord::Base.transaction do
      merge_and_create_availability
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    false
  end

  def success?
    errors.empty?
  end

  private

  def valid_dates?
    if start_date.blank? || end_date.blank?
      @errors << "Start date and end date are required"
      return false
    end

    if end_date < start_date
      @errors << "End date must be after or equal to start date"
      return false
    end

    true
  end

  def merge_and_create_availability
    # Find all overlapping or adjacent availabilities
    overlapping = find_overlapping_availabilities

    if overlapping.any?
      # Store IDs to delete BEFORE creating new record
      ids_to_delete = overlapping.pluck(:id)

      # Calculate the merged range
      all_dates = overlapping.pluck(:start_date, :end_date).flatten + [start_date, end_date]
      merged_start = all_dates.min
      merged_end = all_dates.max

      # Create new availability with merged range
      @availability = Availability.create!(
        user: user,
        group: group,
        start_date: merged_start,
        end_date: merged_end
      )

      # Delete the old overlapping availabilities by ID (ensures we don't delete the new one)
      Availability.where(id: ids_to_delete).delete_all
    else
      # No overlaps, just create new availability
      @availability = Availability.create!(
        user: user,
        group: group,
        start_date: start_date,
        end_date: end_date
      )
    end

    @availability
  end

  def find_overlapping_availabilities
    Availability
      .where(user_id: user.id, group_id: group.id)
      .where("(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)",
             end_date + 1.day, start_date - 1.day,  # Overlaps or adjacent to our range
             start_date, start_date,                 # Starts within our range
             start_date, end_date)                   # Completely within our range
  end
end
