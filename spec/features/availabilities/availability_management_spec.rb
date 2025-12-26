require 'rails_helper'

RSpec.describe "Availability Management", type: :feature, js: true do
  let(:user) { User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:group) { user.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before { login_as user, scope: :user }

  describe "Removing from list" do
    it "removes individual availability and updates calendar and list" do
      availability = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
      visit group_path(group)

      within("#availability_#{availability.id}") { click_button "×" }
      page.driver.browser.switch_to.alert.accept

      expect(page).not_to have_selector("#availability_#{availability.id}")
      expect(group.availabilities.where(user: user).count).to eq(0)
    end

    it "removes multiple availabilities using batch selection" do
      avail1 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
      avail2 = group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 15))
      visit group_path(group)

      check "availability_checkbox_#{avail1.id}"
      check "availability_checkbox_#{avail2.id}"
      click_button I18n.t('groups.show.remove_selected')
      page.driver.browser.switch_to.alert.accept

      expect(page).not_to have_selector("#availability_#{avail1.id}")
      expect(page).not_to have_selector("#availability_#{avail2.id}")
      expect(group.availabilities.where(user: user).count).to eq(0)
    end

    it "shows batch remove button only when items are selected" do
      group.availabilities.create!(user: user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))
      visit group_path(group)

      expect(page).to have_button(I18n.t('groups.show.remove_selected'), visible: false)
    end
  end


  describe "Authorization" do
    it "does not allow removing another user's availability" do
      other_user = User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123")
      group.members << other_user
      other_availability = group.availabilities.create!(user: other_user, start_date: Date.new(2025, 1, 10), end_date: Date.new(2025, 1, 10))

      visit group_path(group)

      within("#availabilities") do
        expect(page).not_to have_content("Jan 10")
      end
    end
  end
end
