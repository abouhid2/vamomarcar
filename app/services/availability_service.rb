class AvailabilityService
  attr_reader :user, :group, :errors, :availability

  def initialize(user:, group:)
    @user = user
    @group = group
    @errors = []
  end

  def add(start_date:, end_date:)
    return false unless validate_dates(start_date, end_date)

    ActiveRecord::Base.transaction do
      merge_and_create(start_date, end_date)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    false
  end

  def remove(start_date:, end_date:)
    return false unless validate_dates(start_date, end_date)

    ActiveRecord::Base.transaction do
      remove_from_availabilities(start_date, end_date)
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

  def validate_dates(start_date, end_date)
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

  def merge_and_create(start_date, end_date)
    overlapping = find_overlapping(start_date, end_date, adjacent: true)

    if overlapping.any?
      ids_to_delete = overlapping.pluck(:id)
      all_dates = overlapping.pluck(:start_date, :end_date).flatten + [start_date, end_date]

      @availability = Availability.create!(
        user: user,
        group: group,
        start_date: all_dates.min,
        end_date: all_dates.max
      )

      Availability.where(id: ids_to_delete).delete_all
    else
      @availability = Availability.create!(
        user: user,
        group: group,
        start_date: start_date,
        end_date: end_date
      )
    end

    @availability
  end

  def remove_from_availabilities(start_date, end_date)
    find_overlapping(start_date, end_date).each do |availability|
      process_removal(availability, start_date, end_date)
    end
  end

  def process_removal(availability, start_date, end_date)
    # Completely covered - delete
    if start_date <= availability.start_date && end_date >= availability.end_date
      availability.destroy!
    # Middle removal - split
    elsif start_date > availability.start_date && end_date < availability.end_date
      original_end = availability.end_date
      availability.update!(end_date: start_date - 1.day)
      Availability.create!(
        user: user,
        group: group,
        start_date: end_date + 1.day,
        end_date: original_end
      )
    # Overlaps start - adjust start
    elsif start_date <= availability.start_date && end_date < availability.end_date
      availability.update!(start_date: end_date + 1.day)
    # Overlaps end - adjust end
    elsif start_date > availability.start_date && end_date >= availability.end_date
      availability.update!(end_date: start_date - 1.day)
    end
  end

  def find_overlapping(start_date, end_date, adjacent: false)
    query = Availability.where(user_id: user.id, group_id: group.id)

    if adjacent
      # For adding: include adjacent dates (for merging)
      query.where(
        "(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)",
        end_date + 1.day, start_date - 1.day,
        start_date, start_date,
        start_date, end_date
      )
    else
      # For removing: only actual overlaps
      query.where(
        "(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)",
        end_date, start_date,
        start_date, start_date,
        start_date, end_date
      )
    end
  end
end
