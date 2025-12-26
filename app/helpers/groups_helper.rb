module GroupsHelper
  def member_availability_days(group, member)
    availabilities = group.availabilities.where(user: member)
    return 0 if availabilities.empty?

    availabilities.sum { |a| (a.end_date - a.start_date).to_i + 1 }
  end

  def member_availability_badge(group, member)
    days = member_availability_days(group, member)
    if days > 0
      content_tag(:span, "#{days}d", class: "text-xs text-green-600 whitespace-nowrap")
    else
      content_tag(:span, "-", class: "text-xs text-gray-400")
    end
  end

  def brazilian_holiday?(date)
    Holidays.on(date, :br).any?
  end

  def brazilian_holiday_name(date)
    holidays = Holidays.on(date, :br)
    holidays.first[:name] if holidays.any?
  end

  def availability_includes_holiday?(availability)
    (availability.start_date..availability.end_date).any? { |date| brazilian_holiday?(date) }
  end

  def format_availability_date_range(availability)
    start_date = availability.start_date
    end_date = availability.end_date
    same_year = start_date.year == end_date.year && start_date.year == Date.today.year

    if availability.single_day?
      format = same_year ? :short : :with_year
      I18n.l(start_date, format: format)
    else
      format = same_year ? :short : :with_year
      "#{I18n.l(start_date, format: format)} - #{I18n.l(end_date, format: format)}"
    end
  end
end
