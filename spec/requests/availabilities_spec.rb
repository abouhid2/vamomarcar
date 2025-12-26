require 'rails_helper'

RSpec.describe "Availabilities", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { user.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as user, scope: :user
  end

  describe "POST /groups/:group_id/availabilities/add_all_holidays" do
    it "creates availabilities for all Brazilian holidays in the year" do
      expect {
        post add_all_holidays_group_availabilities_path(group), params: { year: 2025, current_month: "2025-04-01" }
      }.to change { group.availabilities.count }.by_at_least(5)

      # Check for specific holidays
      availabilities = group.availabilities.where(user: user)
      dates = availabilities.map(&:start_date)

      # New Year
      expect(dates).to include(Date.new(2025, 1, 1))

      # Good Friday
      expect(dates).to include(Date.new(2025, 4, 18))

      # Labor Day
      expect(dates).to include(Date.new(2025, 5, 1))

      # Independence Day
      expect(dates).to include(Date.new(2025, 9, 7))

      # Christmas
      expect(dates).to include(Date.new(2025, 12, 25))
    end

    it "returns a redirect" do
      post add_all_holidays_group_availabilities_path(group), params: { year: 2025, current_month: "2025-04-01" }

      # HTML request should redirect
      expect(response).to have_http_status(:redirect)
    end

    it "merges with existing availabilities" do
      # Create an availability that overlaps with Good Friday (Apr 18)
      group.availabilities.create!(user: user, start_date: Date.new(2025, 4, 17), end_date: Date.new(2025, 4, 19))

      post add_all_holidays_group_availabilities_path(group), params: { year: 2025, current_month: "2025-04-01" }

      # Good Friday (Apr 18) should be covered by the merged availability
      availabilities = group.availabilities.where(user: user)
      good_friday_covered = availabilities.any? do |a|
        a.start_date <= Date.new(2025, 4, 18) && a.end_date >= Date.new(2025, 4, 18)
      end

      expect(good_friday_covered).to be true
    end
  end
end
