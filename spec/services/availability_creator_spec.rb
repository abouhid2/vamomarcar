require 'rails_helper'

RSpec.describe AvailabilityCreator do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:group) { Group.create!(name: 'Test Group', owner: user, is_public: false, weekends_only: false) }

  describe '#call' do
    context 'when creating a new availability with no overlaps' do
      it 'creates a new availability' do
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 5)
        )

        expect { creator.call }.to change { Availability.count }.by(1)
        expect(creator.availability.start_date).to eq(Date.new(2025, 1, 1))
        expect(creator.availability.end_date).to eq(Date.new(2025, 1, 5))
      end
    end

    context 'when adding a date inside an existing range' do
      it 'keeps the original range without deleting it' do
        # First availability: Jan 10-20
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 20)
        )

        # Add Jan 15 (inside the range)
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 15),
          end_date: Date.new(2025, 1, 15)
        )

        expect { creator.call }.not_to change { Availability.count }

        availability = Availability.find_by(user: user, group: group)
        expect(availability.start_date).to eq(Date.new(2025, 1, 10))
        expect(availability.end_date).to eq(Date.new(2025, 1, 20))
      end
    end

    context 'when adding adjacent dates' do
      it 'merges Jan 10-12 and Jan 13 into Jan 10-13' do
        # First availability: Jan 10-12
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 12)
        )

        # Add Jan 13 (adjacent)
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 13),
          end_date: Date.new(2025, 1, 13)
        )

        expect { creator.call }.not_to change { Availability.count }

        availability = Availability.find_by(user: user, group: group)
        expect(availability.start_date).to eq(Date.new(2025, 1, 10))
        expect(availability.end_date).to eq(Date.new(2025, 1, 13))
      end
    end

    context 'when merging overlapping ranges' do
      it 'merges Jan 1-5 and Jan 3-10 into Jan 1-10' do
        # First availability: Jan 1-5
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 5)
        )

        # Add Jan 3-10 (overlapping)
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 3),
          end_date: Date.new(2025, 1, 10)
        )

        expect { creator.call }.not_to change { Availability.count }

        availability = Availability.find_by(user: user, group: group)
        expect(availability.start_date).to eq(Date.new(2025, 1, 1))
        expect(availability.end_date).to eq(Date.new(2025, 1, 10))
      end
    end

    context 'when englobing existing ranges' do
      it 'merges Jan 5-10 and Jan 15-20 when adding Jan 1-25' do
        # First availability: Jan 5-10
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 5),
          end_date: Date.new(2025, 1, 10)
        )

        # Second availability: Jan 15-20
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 15),
          end_date: Date.new(2025, 1, 20)
        )

        # Add Jan 1-25 (englobes both)
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 25)
        )

        creator.call

        availabilities = Availability.where(user: user, group: group)
        expect(availabilities.count).to eq(1)
        expect(availabilities.first.start_date).to eq(Date.new(2025, 1, 1))
        expect(availabilities.first.end_date).to eq(Date.new(2025, 1, 25))
      end
    end

    context 'when dates are not overlapping' do
      it 'keeps both availabilities separate' do
        # First availability: Jan 1-5
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 5)
        )

        # Add Jan 10-15 (not overlapping, not adjacent)
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 15)
        )

        expect { creator.call }.to change { Availability.count }.by(1)

        availabilities = Availability.where(user: user, group: group).order(:start_date)
        expect(availabilities.count).to eq(2)
        expect(availabilities.first.start_date).to eq(Date.new(2025, 1, 1))
        expect(availabilities.first.end_date).to eq(Date.new(2025, 1, 5))
        expect(availabilities.last.start_date).to eq(Date.new(2025, 1, 10))
        expect(availabilities.last.end_date).to eq(Date.new(2025, 1, 15))
      end
    end

    context 'validation errors' do
      it 'returns false and sets errors when end_date is before start_date' do
        creator = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 5)
        )

        expect(creator.call).to be false
        expect(creator.errors).to include("End date must be after or equal to start date")
      end

      it 'returns false and sets errors when dates are blank' do
        creator = described_class.new(
          user: user,
          group: group,
          start_date: nil,
          end_date: nil
        )

        expect(creator.call).to be false
        expect(creator.errors).to include("Start date and end date are required")
      end
    end
  end
end
