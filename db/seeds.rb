# Clear existing data
puts "Clearing existing data..."
Availability.destroy_all
GroupMembership.destroy_all
Group.destroy_all
User.destroy_all

# Create users
puts "Creating users..."
alice = User.create!(email: "alice@example.com", password: "password123", password_confirmation: "password123")
bob = User.create!(email: "bob@example.com", password: "password123", password_confirmation: "password123")
carol = User.create!(email: "carol@example.com", password: "password123", password_confirmation: "password123")
dave = User.create!(email: "dave@example.com", password: "password123", password_confirmation: "password123")
eve = User.create!(email: "eve@example.com", password: "password123", password_confirmation: "password123")
frank = User.create!(email: "frank@example.com", password: "password123", password_confirmation: "password123")

# Create groups
puts "Creating groups..."
trip_group = alice.owned_groups.create!(
  name: "🏖️ Beach Trip - Carnaval 2025",
  description: "Let's plan a beach trip during Carnaval! Looking for dates when everyone is free.",
  is_public: false,
  weekends_only: false
)

weekend_group = bob.owned_groups.create!(
  name: "⚽ Weekend Soccer Games",
  description: "Organizing weekend soccer matches. Weekends and holidays only!",
  is_public: true,
  weekends_only: true
)

study_group = carol.owned_groups.create!(
  name: "📚 Study Group Sessions",
  description: "Weekly study sessions. Find the best times to meet!",
  is_public: false,
  weekends_only: false
)

# Add members to groups
puts "Adding members to groups..."
# Trip group (everyone)
[bob, carol, dave, eve, frank].each { |u| trip_group.group_memberships.create!(user: u) }

# Weekend group (4 members)
[alice, carol, dave, eve].each { |u| weekend_group.group_memberships.create!(user: u) }

# Study group (3 members)
[alice, bob, dave].each { |u| study_group.group_memberships.create!(user: u) }

# Add availabilities for trip group (around Carnaval 2025)
puts "Adding availabilities for trip group..."
# Carnaval is March 3-4, 2025
# Everyone available during Carnaval week
trip_group.availabilities.create!(user: alice, start_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 7))
trip_group.availabilities.create!(user: bob, start_date: Date.new(2025, 2, 28), end_date: Date.new(2025, 3, 5))
trip_group.availabilities.create!(user: carol, start_date: Date.new(2025, 3, 2), end_date: Date.new(2025, 3, 8))
trip_group.availabilities.create!(user: dave, start_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 4))
trip_group.availabilities.create!(user: eve, start_date: Date.new(2025, 3, 3), end_date: Date.new(2025, 3, 10))
trip_group.availabilities.create!(user: frank, start_date: Date.new(2025, 2, 27), end_date: Date.new(2025, 3, 6))

# Some scattered February dates
trip_group.availabilities.create!(user: alice, start_date: Date.new(2025, 2, 14), end_date: Date.new(2025, 2, 16))
trip_group.availabilities.create!(user: bob, start_date: Date.new(2025, 2, 15), end_date: Date.new(2025, 2, 16))
trip_group.availabilities.create!(user: carol, start_date: Date.new(2025, 2, 8), end_date: Date.new(2025, 2, 9))

# Add availabilities for weekend group (January-February weekends)
puts "Adding availabilities for weekend group..."
# Weekend of Jan 4-5 (everyone)
weekend_group.availabilities.create!(user: alice, start_date: Date.new(2025, 1, 4), end_date: Date.new(2025, 1, 5))
weekend_group.availabilities.create!(user: bob, start_date: Date.new(2025, 1, 4), end_date: Date.new(2025, 1, 5))
weekend_group.availabilities.create!(user: carol, start_date: Date.new(2025, 1, 4), end_date: Date.new(2025, 1, 5))
weekend_group.availabilities.create!(user: dave, start_date: Date.new(2025, 1, 4), end_date: Date.new(2025, 1, 5))
weekend_group.availabilities.create!(user: eve, start_date: Date.new(2025, 1, 4), end_date: Date.new(2025, 1, 5))

# Various other weekends (partial availability)
weekend_group.availabilities.create!(user: alice, start_date: Date.new(2025, 1, 11), end_date: Date.new(2025, 1, 12))
weekend_group.availabilities.create!(user: bob, start_date: Date.new(2025, 1, 18), end_date: Date.new(2025, 1, 19))
weekend_group.availabilities.create!(user: carol, start_date: Date.new(2025, 1, 11), end_date: Date.new(2025, 1, 12))
weekend_group.availabilities.create!(user: dave, start_date: Date.new(2025, 1, 25), end_date: Date.new(2025, 1, 26))
weekend_group.availabilities.create!(user: eve, start_date: Date.new(2025, 2, 1), end_date: Date.new(2025, 2, 2))

# Add availabilities for study group (weekdays in January)
puts "Adding availabilities for study group..."
# Week 1
study_group.availabilities.create!(user: alice, start_date: Date.new(2025, 1, 6), end_date: Date.new(2025, 1, 10))
study_group.availabilities.create!(user: bob, start_date: Date.new(2025, 1, 7), end_date: Date.new(2025, 1, 9))
study_group.availabilities.create!(user: carol, start_date: Date.new(2025, 1, 6), end_date: Date.new(2025, 1, 8))
study_group.availabilities.create!(user: dave, start_date: Date.new(2025, 1, 8), end_date: Date.new(2025, 1, 10))

# Week 2
study_group.availabilities.create!(user: alice, start_date: Date.new(2025, 1, 13), end_date: Date.new(2025, 1, 17))
study_group.availabilities.create!(user: bob, start_date: Date.new(2025, 1, 14), end_date: Date.new(2025, 1, 16))
study_group.availabilities.create!(user: carol, start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 15))
study_group.availabilities.create!(user: dave, start_date: Date.new(2025, 1, 13), end_date: Date.new(2025, 1, 14))

# Tiradentes holiday (April 21)
study_group.availabilities.create!(user: alice, start_date: Date.new(2025, 4, 21), end_date: Date.new(2025, 4, 21))
study_group.availabilities.create!(user: bob, start_date: Date.new(2025, 4, 21), end_date: Date.new(2025, 4, 21))
study_group.availabilities.create!(user: carol, start_date: Date.new(2025, 4, 21), end_date: Date.new(2025, 4, 21))
study_group.availabilities.create!(user: dave, start_date: Date.new(2025, 4, 21), end_date: Date.new(2025, 4, 21))

puts "\n✅ Seed data created successfully!"
puts "\n👥 Sample Users (all password: password123):"
puts "  • alice@example.com"
puts "  • bob@example.com"
puts "  • carol@example.com"
puts "  • dave@example.com"
puts "  • eve@example.com"
puts "  • frank@example.com"
puts "\n📅 Groups created:"
puts "  🏖️  Beach Trip - Carnaval 2025 (6 members) - Check March 2025!"
puts "  ⚽  Weekend Soccer Games (5 members, weekends-only) - Perfect match: Jan 4-5!"
puts "  📚  Study Group Sessions (4 members) - All available on Tiradentes (Apr 21)!"
puts "\n💡 Tips:"
puts "  - Login as any user above"
puts "  - Navigate to March 2025 to see Carnaval dates"
puts "  - Check 'See Results' to find perfect match dates"
puts "  - Try the filter buttons (Weekends, Holidays, Weekdays)"
