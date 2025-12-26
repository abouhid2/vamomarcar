require 'rails_helper'

RSpec.describe "Calendar Availability Removal", type: :feature, js: true do
  let(:user) { User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { user.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as user, scope: :user
  end

  it "removes availability from calendar and updates both calendar and list" do
    # Create an availability for a date range
    availability = group.availabilities.create!(
      user: user,
      start_date: Date.new(2025, 1, 10),
      end_date: Date.new(2025, 1, 12)
    )

    visit group_path(group, month: "2025-01-01")

    # Should see the availability in the list
    expect(page).to have_content("Jan 10")
    expect(page).to have_content("Jan 12")

    # Should see the dates highlighted in the calendar with left border
    within("#calendar") do
      expect(page).to have_css("[data-date='2025-01-10'].border-teal-500")
      expect(page).to have_css("[data-date='2025-01-11'].border-teal-500")
      expect(page).to have_css("[data-date='2025-01-12'].border-teal-500")
    end

    # Select dates using JavaScript - simulate the calendar selection by setting the hidden fields
    page.execute_script(<<~JS)
      document.querySelector('[data-calendar-target="startDateInput"]').value = '2025-01-10'
      document.querySelector('[data-calendar-target="endDateInput"]').value = '2025-01-12'
      const removeButton = document.querySelector('[data-calendar-target="removeButton"]')
      removeButton.disabled = false
      removeButton.classList.remove('opacity-50', 'cursor-not-allowed')
    JS

    # Click Remove button
    find("button[data-calendar-target='removeButton']").click

    # Wait for Turbo Stream to update the page
    # Calendar should update - dates should no longer have the teal border
    expect(page).not_to have_css("[data-date='2025-01-10'].border-teal-500")
    expect(page).not_to have_css("[data-date='2025-01-11'].border-teal-500")
    expect(page).not_to have_css("[data-date='2025-01-12'].border-teal-500")

    # List should update - availability should be removed
    expect(page).not_to have_selector("#availability_#{availability.id}")

    # Verify in database
    expect(group.availabilities.where(user: user).count).to eq(0)
  end

  it "partially removes from calendar when removing a subset of dates" do
    # Create an availability for a longer range
    availability = group.availabilities.create!(
      user: user,
      start_date: Date.new(2025, 1, 10),
      end_date: Date.new(2025, 1, 20)
    )

    visit group_path(group, month: "2025-01-01")

    # All dates should be highlighted
    (10..20).each do |day|
      expect(page).to have_css("[data-date='2025-01-#{day.to_s.rjust(2, '0')}'].border-teal-500")
    end

    # Remove middle portion (Jan 13-17) using JavaScript
    page.execute_script(<<~JS)
      document.querySelector('[data-calendar-target="startDateInput"]').value = '2025-01-13'
      document.querySelector('[data-calendar-target="endDateInput"]').value = '2025-01-17'
      const removeButton = document.querySelector('[data-calendar-target="removeButton"]')
      removeButton.disabled = false
      removeButton.classList.remove('opacity-50', 'cursor-not-allowed')
    JS

    # Click Remove button
    find("button[data-calendar-target='removeButton']").click

    # Wait for Turbo Stream updates
    # First part should still be highlighted
    (10..12).each do |day|
      expect(page).to have_css("[data-date='2025-01-#{day.to_s.rjust(2, '0')}'].border-teal-500")
    end

    # Middle part should not be highlighted
    (13..17).each do |day|
      expect(page).not_to have_css("[data-date='2025-01-#{day.to_s.rjust(2, '0')}'].border-teal-500")
    end

    # Last part should still be highlighted
    (18..20).each do |day|
      expect(page).to have_css("[data-date='2025-01-#{day.to_s.rjust(2, '0')}'].border-teal-500")
    end

    # List should show two separate availabilities
    expect(page).to have_content("Jan 10")
    expect(page).to have_content("Jan 12")
    expect(page).to have_content("Jan 18")
    expect(page).to have_content("Jan 20")

    # Verify in database - should have 2 availabilities now (split)
    expect(group.availabilities.where(user: user).count).to eq(2)
  end

  it "removes twice in a row and both calendar and list update correctly" do
    # Create two separate availabilities
    availability1 = group.availabilities.create!(
      user: user,
      start_date: Date.new(2025, 1, 10),
      end_date: Date.new(2025, 1, 12)
    )

    availability2 = group.availabilities.create!(
      user: user,
      start_date: Date.new(2025, 1, 20),
      end_date: Date.new(2025, 1, 22)
    )

    visit group_path(group, month: "2025-01-01")

    # Both should be visible in calendar
    expect(page).to have_css("[data-date='2025-01-10'].border-teal-500")
    expect(page).to have_css("[data-date='2025-01-20'].border-teal-500")

    # Both should be in the list
    expect(page).to have_selector("#availability_#{availability1.id}")
    expect(page).to have_selector("#availability_#{availability2.id}")

    # First removal using JavaScript
    page.execute_script(<<~JS)
      document.querySelector('[data-calendar-target="startDateInput"]').value = '2025-01-10'
      document.querySelector('[data-calendar-target="endDateInput"]').value = '2025-01-12'
      const removeButton = document.querySelector('[data-calendar-target="removeButton"]')
      removeButton.disabled = false
      removeButton.classList.remove('opacity-50', 'cursor-not-allowed')
    JS

    find("button[data-calendar-target='removeButton']").click

    # Wait for first update
    expect(page).not_to have_css("[data-date='2025-01-10'].border-teal-500")
    expect(page).not_to have_selector("#availability_#{availability1.id}")

    # Second availability should still be there
    expect(page).to have_css("[data-date='2025-01-20'].border-teal-500")
    expect(page).to have_selector("#availability_#{availability2.id}")

    # Second removal using JavaScript
    page.execute_script(<<~JS)
      document.querySelector('[data-calendar-target="startDateInput"]').value = '2025-01-20'
      document.querySelector('[data-calendar-target="endDateInput"]').value = '2025-01-22'
      const removeButton = document.querySelector('[data-calendar-target="removeButton"]')
      removeButton.disabled = false
      removeButton.classList.remove('opacity-50', 'cursor-not-allowed')
    JS

    find("button[data-calendar-target='removeButton']").click

    # Wait for second update
    expect(page).not_to have_css("[data-date='2025-01-20'].border-teal-500")
    expect(page).not_to have_selector("#availability_#{availability2.id}")

    # Verify both removed from database
    expect(group.availabilities.where(user: user).count).to eq(0)
  end
end
