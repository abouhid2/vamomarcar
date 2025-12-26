require 'rails_helper'

RSpec.feature "Group Owner CRUD", type: :feature do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:member) { User.create!(email: "member@example.com", password: "password123", password_confirmation: "password123") }
  let!(:group) { owner.owned_groups.create!(name: "Test Group", description: "Original description", is_public: false, weekends_only: false) }

  before do
    group.group_memberships.create!(user: member)
  end

  describe "as the group owner" do
    before do
      login_as(owner, scope: :user)
    end

    it "shows edit and delete buttons on group page" do
      visit group_path(group)

      expect(page).to have_link("Edit", href: edit_group_path(group))
      expect(page).to have_button("Delete")
    end

    it "allows editing the group" do
      visit group_path(group)
      click_link "Edit"

      expect(page).to have_current_path(edit_group_path(group))
      expect(page).to have_content("Edit Group")

      fill_in "Name", with: "Updated Group Name"
      fill_in "Description", with: "Updated description"
      check "Make this group public (anyone can join)"

      click_button "Update Group"

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_content("Updated Group Name")
      expect(page).to have_content("Updated description")
      expect(page).to have_content("Public")
    end

    it "allows deleting the group", js: true do
      visit group_path(group)

      # Accept the confirmation dialog
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(groups_path)
      expect(page).to have_content("Group was successfully deleted")
      expect(Group.exists?(group.id)).to be false
    end

    it "shows cancel button that returns to group page when editing" do
      visit edit_group_path(group)

      click_link "Cancel"

      expect(page).to have_current_path(group_path(group))
    end

    it "shows remove button next to members (but not for the owner)", js: true do
      visit group_path(group)

      # Should show remove button for the member
      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        expect(page).to have_button("×", count: 1) # Only one member can be removed
      end
    end

    it "allows removing a member from the group", js: true do
      visit group_path(group)

      expect(page).to have_content(member.email.split('@').first)

      accept_confirm do
        within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
          click_button("×", match: :first)
        end
      end

      expect(page).to have_content("Member removed from the group")
      expect(page).not_to have_content(member.email.split('@').first)
      expect(group.members.reload).not_to include(member)
    end

    it "cannot remove themselves (the owner)" do
      visit group_path(group)

      # Owner should not have a remove button next to their name
      # We can check by counting the × buttons - should only be 1 (for the member, not the owner)
      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        expect(page).to have_button("×", count: 1) # Only one member (not the owner)
      end
    end
  end

  describe "as a regular member (not owner)" do
    before do
      login_as(member, scope: :user)
    end

    it "does not show edit and delete buttons" do
      visit group_path(group)

      expect(page).not_to have_link("Edit")
      expect(page).not_to have_button("Delete")
    end

    it "cannot access edit page directly" do
      visit edit_group_path(group)

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_content("You are not authorized")
    end

    it "cannot delete the group directly" do
      page.driver.submit :delete, group_path(group), {}

      expect(Group.exists?(group.id)).to be true
    end

    it "does not see remove buttons for other members" do
      visit group_path(group)

      within(".bg-white.rounded-lg.shadow-md.p-4", text: "Members") do
        expect(page).not_to have_button("×")
      end
    end
  end
end
