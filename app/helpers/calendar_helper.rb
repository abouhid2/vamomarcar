module CalendarHelper
  def calendar_data_for_month(date, group, current_user)
    # Normalize to beginning of month
    start_of_month = date.beginning_of_month
    end_of_month = date.end_of_month

    # Get first day of calendar grid (might be in previous month)
    # Start from the Sunday before or on the first day of month
    calendar_start = start_of_month.beginning_of_week(:sunday)

    # Get last day of calendar grid (might be in next month)
    # End on the Saturday after or on the last day of month
    calendar_end = end_of_month.end_of_week(:sunday)

    # Calculate all days in the grid
    days_in_grid = (calendar_start..calendar_end).to_a

    # Eager load all availabilities for the group
    availabilities = group.availabilities.includes(:user).to_a

    # Get all group members for percentage calculation
    total_members = group.all_users.count

    # Build calendar data
    {
      year: date.year,
      month: date.month,
      month_name: date.strftime("%B %Y"),
      prev_month: (date - 1.month).beginning_of_month,
      next_month: (date + 1.month).beginning_of_month,
      days: days_in_grid.map do |day|
        # Find which users are available on this day
        users_available = availabilities.select do |avail|
          avail.date_range.include?(day)
        end.map(&:user).uniq

        # Check if current user is available
        current_user_available = users_available.any? { |u| u.id == current_user.id }

        # Check if day is a Brazilian holiday
        is_holiday = Holidays.on(day, :br).any?
        is_weekend = day.weekend?
        holiday_name = is_holiday ? Holidays.on(day, :br).first[:name] : nil

        # Check if day is disabled (weekends_only filter)
        is_disabled = group.weekends_only && !(is_weekend || is_holiday)

        {
          date: day,
          day_number: day.day,
          is_weekend: is_weekend,
          is_holiday: is_holiday,
          holiday_name: holiday_name,
          is_today: day == Date.today,
          is_in_month: day.month == date.month,
          disabled: is_disabled,
          users: users_available,
          user_count: users_available.count,
          total_members: total_members,
          current_user_available: current_user_available,
          percentage: total_members > 0 ? (users_available.count.to_f / total_members * 100).round : 0
        }
      end
    }
  end

  def availability_percentage_class(percentage)
    if percentage == 100
      "bg-green-100 text-green-800"
    elsif percentage >= 75
      "bg-blue-100 text-blue-800"
    elsif percentage >= 50
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
