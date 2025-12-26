require 'rails_helper'

RSpec.feature "Select All Holidays", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let!(:group) { owner.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as(owner, scope: :user)
  end

  it "shows the 'Select All Holidays' button", js: true do
    # Navigate to April 2025 which has Tiradentes holiday on April 21
    visit group_path(group, month: "2025-04-01")

    expect(page).to have_button("🎉 Select All Holidays")
  end

  it "selects all holidays in the current month when button is clicked", js: true do
    # Navigate to April 2025 which has Tiradentes holiday on April 21
    visit group_path(group, month: "2025-04-01")

    # Click the "Select All Holidays" button
    click_button "🎉 Select All Holidays"

    # The holiday should be selected (visually indicated)
    # We can check this by verifying the selection text or by checking the form fields
    expect(page).to have_content("Selected: 1 holiday")

    # The Add button should be enabled
    expect(page).to have_button("Add", disabled: false)
  end

  it "allows adding selected holidays as availability", js: true do
    # Navigate to April 2025 which has Tiradentes holiday on April 21
    visit group_path(group, month: "2025-04-01")

    # Click the "Select All Holidays" button
    click_button "🎉 Select All Holidays"

    # Submit the form to add availability
    click_button "Add"

    # Should show the holiday in the availability list
    expect(page).to have_content("Apr 21")

    # Verify the availability was created
    availability = group.availabilities.where(user: owner).first
    expect(availability).to be_present
    expect(availability.start_date).to eq(Date.new(2025, 4, 21))
    expect(availability.end_date).to eq(Date.new(2025, 4, 21))
  end

  it "shows an alert when no holidays are found in the month", js: true do
    # Navigate to a month with no holidays (e.g., March 2025)
    visit group_path(group, month: "2025-03-01")

    # Click the "Select All Holidays" button
    accept_alert do
      click_button "🎉 Select All Holidays"
    end
  end

  it "selects multiple holidays when available", js: true do
    # Navigate to November 2025 which has multiple holidays
    # November 2: Finados (All Souls' Day)
    # November 15: Proclamação da República
    # November 20: Dia da Consciência Negra (in some states)
    visit group_path(group, month: "2025-11-01")

    # Click the "Select All Holidays" button
    click_button "🎉 Select All Holidays"

    # Should show multiple holidays selected
    # The exact number depends on which holidays are in the holidays gem for Brazil
    expect(page).to have_content(/Selected: \d+ holiday/)

    # The Add button should be enabled
    expect(page).to have_button("Add", disabled: false)
  end
end
