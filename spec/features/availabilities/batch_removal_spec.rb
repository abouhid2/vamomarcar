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
    check "availability_#{availability1.id}"
    check "availability_#{availability3.id}"

    # Click remove selected button
    click_button "Remove Selected"

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

  it "shows remove selected button only when items are selected" do
    group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

    visit group_path(group)

    # Button should be hidden initially
    expect(page).to have_button("Remove Selected", visible: false)

    # Select an availability
    check "availability_"

    # Button should be visible
    expect(page).to have_button("Remove Selected", visible: true)
  end
end
