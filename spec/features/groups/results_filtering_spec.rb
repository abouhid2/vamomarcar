require 'rails_helper'

RSpec.feature "Groups Results Filtering", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:member) { User.create!(email: "member@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { owner.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    group.group_memberships.create!(user: member)
    login_as(owner, scope: :user)
  end

  describe "filtering by holidays" do
    before do
      # Tiradentes is April 21 (Brazilian holiday)
      tiradentes = Date.new(2025, 4, 21)

      # Regular weekday
      weekday = Date.new(2025, 4, 22)

      # Weekend
      weekend = Date.new(2025, 4, 26) # Saturday

      # Create availabilities
      group.availabilities.create!(user: owner, start_date: tiradentes, end_date: tiradentes)
      group.availabilities.create!(user: member, start_date: tiradentes, end_date: tiradentes)

      group.availabilities.create!(user: owner, start_date: weekday, end_date: weekday)
      group.availabilities.create!(user: member, start_date: weekday, end_date: weekday)

      group.availabilities.create!(user: owner, start_date: weekend, end_date: weekend)
      group.availabilities.create!(user: member, start_date: weekend, end_date: weekend)
    end

    it "renders dates with correct data-is-holiday attributes", js: true do
      visit results_group_path(group)

      # Check that we have 3 result items
      expect(page).to have_selector('[data-results-filter-target="resultItem"]', count: 3)

      # Find the Tiradentes date and check its data attribute
      tiradentes_item = page.find('[data-results-filter-target="resultItem"]', text: 'April 21, 2025')
      expect(tiradentes_item['data-is-holiday']).to eq('true')

      # Find the weekday and check it's not a holiday
      weekday_item = page.find('[data-results-filter-target="resultItem"]', text: 'April 22, 2025')
      expect(weekday_item['data-is-holiday']).to eq('false')

      # Find the weekend and check it's not a holiday
      weekend_item = page.find('[data-results-filter-target="resultItem"]', text: 'April 26, 2025')
      expect(weekend_item['data-is-holiday']).to eq('false')
      expect(weekend_item['data-is-weekend']).to eq('true')
    end

    it "filters to show only holidays when holiday button is clicked", js: true do
      visit results_group_path(group)

      # Initially all 3 dates should be visible
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', count: 3)

      # Click the holidays filter button
      click_button "🎉 Holidays Only"

      # Only the holiday should be visible
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', count: 1)
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', text: 'April 21, 2025')

      # The other dates should be hidden
      weekday_item = page.find('[data-results-filter-target="resultItem"]', text: 'April 22, 2025', visible: false)
      expect(weekday_item[:class]).to include('hidden')

      weekend_item = page.find('[data-results-filter-target="resultItem"]', text: 'April 26, 2025', visible: false)
      expect(weekend_item[:class]).to include('hidden')
    end

    it "filters to show only weekends when weekend button is clicked", js: true do
      visit results_group_path(group)

      # Click the weekends filter button
      click_button "Weekends Only"

      # Only the weekend should be visible
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', count: 1)
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', text: 'April 26, 2025')
    end

    it "shows all dates when 'All Days' button is clicked", js: true do
      visit results_group_path(group)

      # Filter to holidays first
      click_button "🎉 Holidays Only"
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', count: 1)

      # Click "All Days" to reset
      click_button "All Days"

      # All dates should be visible again
      expect(page).to have_selector('[data-results-filter-target="resultItem"]:not(.hidden)', count: 3)
    end

    it "updates the count when filtering", js: true do
      visit results_group_path(group)

      # Check initial count
      expect(page).to have_selector('[data-results-filter-target="count"]', text: '(3 dates)')

      # Filter to holidays
      click_button "🎉 Holidays Only"

      # Count should update
      expect(page).to have_selector('[data-results-filter-target="count"]', text: '(1 dates)')

      # Filter to weekends
      click_button "Weekends Only"

      # Count should update
      expect(page).to have_selector('[data-results-filter-target="count"]', text: '(1 dates)')

      # Show all
      click_button "All Days"

      # Count should be back to 3
      expect(page).to have_selector('[data-results-filter-target="count"]', text: '(3 dates)')
    end
  end
end
