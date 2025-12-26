# Extend Date class with custom methods
class Date
  # Check if date is a weekend (Friday, Saturday, or Sunday)
  # In Brazilian context, weekends include Friday as it's often a travel day
  def weekend?
    [0, 5, 6].include?(wday)
  end
end
