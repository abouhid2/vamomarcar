require 'rails_helper'

RSpec.describe "Batch Availability Removal", type: :feature, js: true do
  let(:user) { User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { user.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as user, scope: :user
  end

  it "allows user to select and remove multiple availabilities at once" do
    # Create multiple availabilities
    availability1 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
    availability2 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 15))
    availability3 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 20), end_date: Date.new(2025, 1, 20))

    visit group_path(group)

    # Should see all three availabilities
    expect(page).to have_content("Jan 10")
    expect(page).to have_content("Jan 15")
    expect(page).to have_content("Jan 20")

    # Select two availabilities (using checkboxes or data attributes)
    check "availability_checkbox_#{availability1.id}"
    check "availability_checkbox_#{availability3.id}"

    # Click Remove button
    click_button "Remove"

    # Should confirm deletion
    page.driver.browser.switch_to.alert.accept

    # Should only see the remaining availability
    expect(page).not_to have_content("Jan 10")
    expect(page).to have_content("Jan 15")
    expect(page).not_to have_content("Jan 20")

    # Verify in database
    expect(group.availabilities.where(user: user).count).to eq(1)
    expect(group.availabilities.where(user: user).first.id).to eq(availability2.id)
  end

  it "shows Remove button only when items are selected" do
    availability = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

    visit group_path(group)

    # Button should be hidden initially
    expect(page).to have_button("Remove", visible: false)

    # Select an availability
    check "availability_checkbox_#{availability.id}"

    # Button should be visible
    expect(page).to have_button("Remove", visible: true)
  end

  it "has correct Stimulus targets on batch removal form" do
    availability = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

    visit group_path(group)

    # The form should have both 'form' and 'removeButton' as Stimulus targets
    form = find("form[action='#{batch_destroy_group_availabilities_path(group)}']", visible: false)
    targets = form["data-batch-select-target"]

    # Should have both targets space-separated
    expect(targets).to include("form")
    expect(targets).to include("removeButton")
  end

  it "submits batch deletion via DELETE method" do
    availability1 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
    availability2 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 15))

    visit group_path(group)

    # Verify form method is DELETE
    form = find("form[action='#{batch_destroy_group_availabilities_path(group)}']", visible: false)
    method_input = form.find("input[name='_method']", visible: false)
    expect(method_input.value).to eq("delete")

    # Perform deletion to ensure it works
    check "availability_checkbox_#{availability1.id}"
    check "availability_checkbox_#{availability2.id}"

    click_button "Remove"
    page.driver.browser.switch_to.alert.accept

    # Wait for Turbo Stream to update the page
    expect(page).not_to have_selector("#availability_#{availability1.id}")
    expect(page).not_to have_selector("#availability_#{availability2.id}")

    # Both should be deleted
    expect(group.availabilities.where(user: user).count).to eq(0)
  end
end
