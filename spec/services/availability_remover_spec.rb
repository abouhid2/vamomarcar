require 'rails_helper'

RSpec.describe AvailabilityRemover do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:group) { Group.create!(name: 'Test Group', owner: user, is_public: false, weekends_only: false) }

  describe '#call' do
    context 'when removing a single day that exists' do
      it 'deletes the availability' do
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 15),
          end_date: Date.new(2025, 1, 15)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 15),
          end_date: Date.new(2025, 1, 15)
        )

        expect { remover.call }.to change { Availability.count }.by(-1)
      end
    end

    context 'when removing a range that completely covers an availability' do
      it 'deletes the availability' do
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 15)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 5),
          end_date: Date.new(2025, 1, 20)
        )

        expect { remover.call }.to change { Availability.count }.by(-1)
      end
    end

    context 'when removing dates that overlap the start of an availability' do
      it 'adjusts the availability start date' do
        availability = Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 20)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 5),
          end_date: Date.new(2025, 1, 12)
        )

        remover.call
        availability.reload

        expect(availability.start_date).to eq(Date.new(2025, 1, 13))
        expect(availability.end_date).to eq(Date.new(2025, 1, 20))
      end
    end

    context 'when removing dates that overlap the end of an availability' do
      it 'adjusts the availability end date' do
        availability = Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 20)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 18),
          end_date: Date.new(2025, 1, 25)
        )

        remover.call
        availability.reload

        expect(availability.start_date).to eq(Date.new(2025, 1, 10))
        expect(availability.end_date).to eq(Date.new(2025, 1, 17))
      end
    end

    context 'when removing dates in the middle of an availability' do
      it 'splits the availability into two' do
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 31)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 20)
        )

        expect { remover.call }.to change { Availability.count }.by(1)

        availabilities = Availability.where(user: user, group: group).order(:start_date)
        expect(availabilities.count).to eq(2)
        expect(availabilities.first.start_date).to eq(Date.new(2025, 1, 1))
        expect(availabilities.first.end_date).to eq(Date.new(2025, 1, 9))
        expect(availabilities.last.start_date).to eq(Date.new(2025, 1, 21))
        expect(availabilities.last.end_date).to eq(Date.new(2025, 1, 31))
      end
    end

    context 'when removing dates that do not overlap any availability' do
      it 'does nothing' do
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 5)
        )

        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 15)
        )

        expect { remover.call }.not_to change { Availability.count }
      end
    end

    context 'when removing dates that overlap multiple availabilities' do
      it 'removes or adjusts all overlapping availabilities' do
        # First availability: Jan 1-5
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 1, 5)
        )

        # Second availability: Jan 10-15
        Availability.create!(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 15)
        )

        # Remove Jan 3-12 (overlaps both)
        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 3),
          end_date: Date.new(2025, 1, 12)
        )

        remover.call

        availabilities = Availability.where(user: user, group: group).order(:start_date)
        expect(availabilities.count).to eq(2)

        # First availability should be adjusted to Jan 1-2
        expect(availabilities.first.start_date).to eq(Date.new(2025, 1, 1))
        expect(availabilities.first.end_date).to eq(Date.new(2025, 1, 2))

        # Second availability should be adjusted to Jan 13-15
        expect(availabilities.last.start_date).to eq(Date.new(2025, 1, 13))
        expect(availabilities.last.end_date).to eq(Date.new(2025, 1, 15))
      end
    end

    context 'validation errors' do
      it 'returns false and sets errors when end_date is before start_date' do
        remover = described_class.new(
          user: user,
          group: group,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 5)
        )

        expect(remover.call).to be false
        expect(remover.errors).to include("End date must be after or equal to start date")
      end

      it 'returns false and sets errors when dates are blank' do
        remover = described_class.new(
          user: user,
          group: group,
          start_date: nil,
          end_date: nil
        )

        expect(remover.call).to be false
        expect(remover.errors).to include("Start date and end date are required")
      end
    end
  end
end
