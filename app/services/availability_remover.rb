class AvailabilityRemover
  attr_reader :user, :group, :start_date, :end_date, :errors

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
      remove_from_availabilities
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

  def remove_from_availabilities
    overlapping = find_overlapping_availabilities

    overlapping.each do |availability|
      process_availability_removal(availability)
    end
  end

  def process_availability_removal(availability)
    # Case 1: Removal range completely covers the availability - delete it
    if start_date <= availability.start_date && end_date >= availability.end_date
      availability.destroy!
      return
    end

    # Case 2: Removal range is in the middle - split into two
    if start_date > availability.start_date && end_date < availability.end_date
      # Store original end date before updating
      original_end_date = availability.end_date

      # Keep the first part
      availability.update!(end_date: start_date - 1.day)

      # Create the second part
      Availability.create!(
        user: user,
        group: group,
        start_date: end_date + 1.day,
        end_date: original_end_date
      )
      return
    end

    # Case 3: Removal range overlaps the start - adjust start date
    if start_date <= availability.start_date && end_date < availability.end_date
      availability.update!(start_date: end_date + 1.day)
      return
    end

    # Case 4: Removal range overlaps the end - adjust end date
    if start_date > availability.start_date && end_date >= availability.end_date
      availability.update!(end_date: start_date - 1.day)
      return
    end
  end

  def find_overlapping_availabilities
    Availability
      .where(user_id: user.id, group_id: group.id)
      .where("(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)",
             end_date, start_date,
             start_date, start_date,
             start_date, end_date)
  end
end
