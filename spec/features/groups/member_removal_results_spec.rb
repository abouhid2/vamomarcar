require 'rails_helper'

RSpec.feature "Member Removal Updates Results", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:member1) { User.create!(email: "member1@example.com", password: "password123", password_confirmation: "password123") }
  let(:member2) { User.create!(email: "member2@example.com", password: "password123", password_confirmation: "password123") }
  let(:member3) { User.create!(email: "member3@example.com", password: "password123", password_confirmation: "password123") }
  let(:member4) { User.create!(email: "member4@example.com", password: "password123", password_confirmation: "password123") }
  let!(:group) { owner.owned_groups.create!(name: "Test Group", description: "Test", is_public: false, weekends_only: false) }

  before do
    # Add all members to the group (total: 5 people including owner)
    [member1, member2, member3, member4].each do |member|
      group.group_memberships.create!(user: member)
    end

    # Create a test date
    test_date = Date.new(2025, 5, 15)

    # Owner, member1, and member2 are available (3 people)
    group.availabilities.create!(user: owner, start_date: test_date, end_date: test_date)
    group.availabilities.create!(user: member1, start_date: test_date, end_date: test_date)
    group.availabilities.create!(user: member2, start_date: test_date, end_date: test_date)

    # member3 and member4 are NOT available (2 people)

    login_as(owner, scope: :user)
  end

  it "updates results count when a member who was available is removed", js: true do
    # Initially: 3/5 people available (owner, member1, member2)
    visit results_group_path(group)

    expect(page).to have_content("May 15, 2025")
    expect(page).to have_content("3 of 5")
    expect(page).to have_content("60.0%") # 3/5 = 60%

    # Remove member1 who was available
    visit group_path(group)

    accept_confirm do
      # Find and click the remove button for member1
      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        # Find the row with member1 and click its remove button
        row = page.find(".bg-gray-50", text: "member1")
        within(row) do
          click_button("×")
        end
      end
    end

    expect(page).to have_content("Member removed from the group")

    # Now check results: should be 2/4 (owner and member2 out of 4 remaining members)
    visit results_group_path(group)

    expect(page).to have_content("May 15, 2025")
    expect(page).to have_content("2 of 4") # member1 removed, so only owner and member2 available out of 4 total
    expect(page).to have_content("50.0%") # 2/4 = 50%
  end

  it "updates results count when a member who was NOT available is removed", js: true do
    # Initially: 3/5 people available
    visit results_group_path(group)

    expect(page).to have_content("3 of 5")
    expect(page).to have_content("60.0%")

    # Remove member3 who was NOT available
    visit group_path(group)

    accept_confirm do
      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        row = page.find(".bg-gray-50", text: "member3")
        within(row) do
          click_button("×")
        end
      end
    end

    # Now check results: should be 3/4 (same 3 people available, but total reduced to 4)
    visit results_group_path(group)

    expect(page).to have_content("May 15, 2025")
    expect(page).to have_content("3 of 4") # 3 people still available, but out of 4 total now
    expect(page).to have_content("75.0%") # 3/4 = 75%
  end

  it "removes the member's availabilities when they are removed from the group", js: true do
    # member1 has availability for May 15
    expect(group.availabilities.where(user: member1).count).to eq(1)

    visit group_path(group)

    accept_confirm do
      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        row = page.find(".bg-gray-50", text: "member1")
        within(row) do
          click_button("×")
        end
      end
    end

    # Wait for the success message
    expect(page).to have_content("Member removed from the group")

    # member1's availability should be deleted
    expect(group.availabilities.reload.where(user: member1).count).to eq(0)

    # Results should show only 2 people available now (not 3)
    visit results_group_path(group)

    expect(page).to have_content("2 of 4")
    expect(page).to have_content("50.0%")
  end
end
