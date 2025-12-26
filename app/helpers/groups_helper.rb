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
end
