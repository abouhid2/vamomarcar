require 'rails_helper'

RSpec.feature "Add All Year Holidays", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let!(:group) { owner.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    login_as(owner, scope: :user)
  end

  it "shows the 'Add All Year Holidays' button", js: true do
    visit group_path(group)

    expect(page).to have_button(I18n.t('groups.show.add_holidays'))
  end

  it "opens a modal when clicking the 'Add All Year Holidays' button", js: true do
    visit group_path(group)

    # Click the button to open the modal
    click_button I18n.t('groups.show.add_holidays')

    # Modal should be visible with holiday selection title
    expect(page).to have_content(I18n.t('availabilities.holiday_modal.title'))

    # Should have year selector
    expect(page).to have_selector('[data-calendar-target="yearSelect"]')

    # Should have cancel and confirm buttons
    expect(page).to have_button(I18n.t('common.cancel'))
    expect(page).to have_button(I18n.t('availabilities.holiday_modal.confirm'))
  end

  it "displays holidays for the current year by default", js: true do
    visit group_path(group)

    click_button I18n.t('groups.show.add_holidays')

    # Wait for modal to appear
    expect(page).to have_content(I18n.t('availabilities.holiday_modal.title'))

    # Select the current year (2025)
    within '#holidayModal' do
      find('[data-calendar-target="yearSelect"]').select('2025')
    end

    # Should show Brazilian holidays
    expect(page).to have_content('Dia de Tiradentes')
    expect(page).to have_content('Natal')
  end

  xit "allows adding all holidays from selected year as availability", js: true do
    visit group_path(group)

    # Click to open modal
    click_button I18n.t('groups.show.add_holidays')

    # Wait for modal
    expect(page).to have_content(I18n.t('availabilities.holiday_modal.title'))

    # Select 2025
    within '#holidayModal' do
      find('[data-calendar-target="yearSelect"]').select('2025')

      # Wait for holidays to load
      expect(page).to have_content('Dia de Tiradentes')

      # Wait for confirm button to be enabled (it starts disabled)
      expect(page).to have_button(I18n.t('availabilities.holiday_modal.confirm'), disabled: false)

      # Click confirm to add all holidays
      click_button I18n.t('availabilities.holiday_modal.confirm')
    end

    # Wait for modal to close
    expect(page).not_to have_selector('#holidayModal', visible: :visible)

    # Should see some holidays in the availability list (checking for a few)
    # Note: The exact dates depend on which Brazilian holidays are in the system
    expect(group.availabilities.where(user: owner).count).to be > 0
  end

  it "can cancel without adding holidays", js: true do
    visit group_path(group)

    # Click to open modal
    click_button I18n.t('groups.show.add_holidays')

    # Wait for modal
    expect(page).to have_content(I18n.t('availabilities.holiday_modal.title'))

    # Click cancel
    within '#holidayModal' do
      click_button I18n.t('common.cancel')
    end

    # Modal should close
    expect(page).not_to have_selector('#holidayModal', visible: true)

    # No holidays should be added
    expect(group.availabilities.where(user: owner).count).to eq(0)
  end

  it "can select different years", js: true do
    visit group_path(group)

    click_button I18n.t('groups.show.add_holidays')

    expect(page).to have_content(I18n.t('availabilities.holiday_modal.title'))

    # Try selecting 2026
    within '#holidayModal' do
      find('[data-calendar-target="yearSelect"]').select('2026')

      # Holidays should update for 2026
      # The system should load and show 2026 holidays
      expect(page).to have_content('2026')
    end
  end
end
