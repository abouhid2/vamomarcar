require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:owner) { User.create!(email: 'owner@example.com', password: 'password123') }

  describe "invitation token generation" do
    it "generates token on create for private groups" do
      group = Group.new(name: 'Private Group', is_public: false, owner: owner)
      expect(group.invitation_token).to be_nil
      group.save!
      expect(group.invitation_token).to be_present
      expect(group.invitation_token.length).to eq(32) # urlsafe_base64(24) = 32 chars
    end

    it "doesn't generate token for public groups" do
      group = Group.create!(name: 'Public Group', is_public: true, owner: owner)
      expect(group.invitation_token).to be_nil
    end

    it "ensures token uniqueness" do
      group1 = Group.create!(name: 'Group 1', is_public: false, owner: owner)
      group2 = Group.create!(name: 'Group 2', is_public: false, owner: owner)
      expect(group1.invitation_token).not_to eq(group2.invitation_token)
    end
  end

  describe "#invitation_url" do
    let(:group) { Group.create!(name: 'Test Group', is_public: false, owner: owner) }

    it "returns full URL with token" do
      url = group.invitation_url('http://example.com')
      expect(url).to eq("http://example.com/groups/#{group.id}/join?token=#{group.invitation_token}")
    end

    it "returns nil if no token exists" do
      group.update_column(:invitation_token, nil)
      expect(group.invitation_url('http://example.com')).to be_nil
    end
  end

  describe "#member?" do
    let(:member) { User.create!(email: 'member@example.com', password: 'password123') }
    let(:non_member) { User.create!(email: 'nonmember@example.com', password: 'password123') }
    let(:group) { Group.create!(name: 'Test Group', owner: owner) }

    before do
      group.group_memberships.create!(user: member)
    end

    it "returns true for owner" do
      expect(group.member?(owner)).to be true
    end

    it "returns true for member" do
      expect(group.member?(member)).to be true
    end

    it "returns false for non-member" do
      expect(group.member?(non_member)).to be false
    end
  end

  describe "#regenerate_invitation_token!" do
    let(:group) { Group.create!(name: 'Test Group', is_public: false, owner: owner) }

    it "generates a new token" do
      old_token = group.invitation_token
      group.regenerate_invitation_token!
      expect(group.invitation_token).not_to eq(old_token)
      expect(group.invitation_token).to be_present
    end
  end

  describe "#enable_invitations!" do
    let(:group) { Group.create!(name: 'Test Group', is_public: false, invitation_enabled: false, owner: owner) }

    it "enables invitations and generates token if missing" do
      group.update_column(:invitation_token, nil)
      group.enable_invitations!
      expect(group.invitation_enabled).to be true
      expect(group.invitation_token).to be_present
    end
  end

  describe "#disable_invitations!" do
    let(:group) { Group.create!(name: 'Test Group', is_public: false, invitation_enabled: true, owner: owner) }

    it "disables invitations" do
      group.disable_invitations!
      expect(group.invitation_enabled).to be false
    end
  end
end
