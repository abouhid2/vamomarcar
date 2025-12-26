require 'rails_helper'

RSpec.feature "Add All Year Holidays", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let!(:group) { owner.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as(owner, scope: :user)
  end

  it "shows the 'Add All Year Holidays' button", js: true do
    visit group_path(group, month: "2025-04-01")

    expect(page).to have_button("🎉 Add All Year Holidays")
  end

  it "adds all holidays for the current year when button is clicked", js: true do
    # Navigate to April 2025
    visit group_path(group, month: "2025-04-01")

    # Initially no availabilities
    expect(group.availabilities.where(user: owner).count).to eq(0)

    # Click the button
    click_button "🎉 Add All Year Holidays"

    # Wait for availabilities to appear in the sidebar
    expect(page).to have_content(/Jan|Apr|May|Sep|Dec/, wait: 10)

    # Should have created availabilities for all Brazilian holidays in 2025
    # Let's check for some known holidays:
    # - New Year (Jan 1)
    # - Tiradentes (Apr 21)
    # - Labor Day (May 1)
    # - Independence Day (Sep 7)
    # - Republic Day (Nov 15)
    # - Christmas (Dec 25)

    availabilities = group.availabilities.reload.where(user: owner)
    expect(availabilities.count).to be > 0

    # Check for specific holidays
    dates = availabilities.map(&:start_date)

    # New Year
    expect(dates).to include(Date.new(2025, 1, 1))

    # Tiradentes
    expect(dates).to include(Date.new(2025, 4, 21))

    # Labor Day
    expect(dates).to include(Date.new(2025, 5, 1))

    # Independence Day
    expect(dates).to include(Date.new(2025, 9, 7))

    # Christmas
    expect(dates).to include(Date.new(2025, 12, 25))
  end

  it "merges holidays with existing availabilities", js: true do
    # Add an availability that includes Tiradentes (Apr 21)
    group.availabilities.create!(
      user: owner,
      start_date: Date.new(2025, 4, 20),
      end_date: Date.new(2025, 4, 22)
    )

    visit group_path(group, month: "2025-04-01")

    click_button "🎉 Add All Year Holidays"

    # Wait for completion
    sleep 1

    # Should have merged the holidays with the existing availability
    availabilities = group.availabilities.reload.where(user: owner)

    # The availability that includes Apr 20-22 should have been extended
    # if there are other holidays nearby, or kept as is
    # The important thing is that we don't have duplicate dates
    expect(availabilities.count).to be > 0

    # Tiradentes should be covered
    tiradentes_covered = availabilities.any? do |a|
      a.start_date <= Date.new(2025, 4, 21) && a.end_date >= Date.new(2025, 4, 21)
    end
    expect(tiradentes_covered).to be true
  end

  it "shows the availabilities in the list after adding", js: true do
    visit group_path(group, month: "2025-04-01")

    click_button "🎉 Add All Year Holidays"

    # Wait for completion
    sleep 1

    # Should show some availabilities in the sidebar
    within "#availabilities" do
      expect(page).to have_content(/Jan|Apr|May|Sep|Dec/)
    end
  end
end
