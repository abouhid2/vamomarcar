require 'rails_helper'

RSpec.describe "Individual Availability Removal", type: :feature, js: true do
  let(:user) { User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { user.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as user, scope: :user
  end

  it "allows user to remove a single availability using the × button" do
    # Create multiple availabilities
    availability1 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
    availability2 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 15))
    availability3 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 20), end_date: Date.new(2025, 1, 20))

    visit group_path(group)

    # Should see all three availabilities
    expect(page).to have_content("Jan 10")
    expect(page).to have_content("Jan 15")
    expect(page).to have_content("Jan 20")

    # Find and click the × button for the second availability
    within("#availability_#{availability2.id}") do
      click_button "×"
    end

    # Should confirm deletion
    page.driver.browser.switch_to.alert.accept

    # Should see remaining availabilities but not the deleted one
    expect(page).to have_content("Jan 10")
    expect(page).not_to have_content("Jan 15")
    expect(page).to have_content("Jan 20")

    # Verify in database
    expect(group.availabilities.where(user: user).count).to eq(2)
    expect(group.availabilities.where(user: user).pluck(:id)).to contain_exactly(availability1.id, availability3.id)
  end

  it "removes a date range availability" do
    # Create a date range availability
    availability = group.availabilities.create!(
      user: user,
      start_date: Date.new(2025, 1, 10),
      end_date: Date.new(2025, 1, 15)
    )

    visit group_path(group)

    # Should see the date range
    expect(page).to have_content("Jan 10")
    expect(page).to have_content("Jan 15")

    # Click the × button
    within("#availability_#{availability.id}") do
      click_button "×"
    end

    # Confirm deletion
    page.driver.browser.switch_to.alert.accept

    # Should not see the date range anymore
    expect(page).not_to have_content("Jan 10 - Jan 15")

    # Verify in database
    expect(group.availabilities.where(user: user).count).to eq(0)
  end

  it "updates the calendar after removing an availability" do
    availability = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

    visit group_path(group)

    # Calendar should show the availability (this would need to check the calendar UI)
    # For now, just verify the list is updated
    expect(page).to have_content("Jan 10")

    # Remove the availability
    within("#availability_#{availability.id}") do
      click_button "×"
    end

    page.driver.browser.switch_to.alert.accept

    # Should show "no availability" message
    expect(page).to have_content(I18n.t('groups.show.no_availability'))
  end

  it "does not allow removing another user's availability" do
    other_user = User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123")
    group.members << other_user

    # Create availability for other user
    other_availability = group.availabilities.create!(
      user: other_user,
      start_date: Date.new(2025, 1, 10),
      end_date: Date.new(2025, 1, 10)
    )

    visit group_path(group)

    # Should not see × button for other user's availability in current user's list
    within("[data-controller='batch-select']") do
      expect(page).not_to have_content("Jan 10")
    end
  end

  it "sends DELETE request when clicking × button (not GET)" do
    availability = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

    visit group_path(group)

    # Verify the button submits with DELETE method
    within("#availability_#{availability.id}") do
      delete_form = find("form[action*='/availabilities/#{availability.id}']")
      expect(delete_form.find("input[name='_method']", visible: false).value).to eq("delete")
    end

    # Click and verify it actually deletes (not a GET request that would fail)
    within("#availability_#{availability.id}") do
      click_button "×"
    end

    page.driver.browser.switch_to.alert.accept

    # Should successfully delete (if it was sending GET, it would error)
    expect(page).not_to have_content("Jan 10")
    expect(group.availabilities.where(user: user).count).to eq(0)
  end
end
