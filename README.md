# Bora Marcar - Family Meetup Coordinator

A Ruby on Rails application that helps families and groups coordinate meetups by finding optimal dates when everyone is available.

## Features

- **User Authentication**: Secure sign-up and sign-in using Devise
- **Group Management**: Create public or private groups for coordinating meetups
- **Flexible Availability Selection**: Add individual dates or date ranges
- **Smart Date Matching**: Algorithm that shows the best meeting dates ranked by availability
- **Real-time Updates**: Hotwire (Turbo) for seamless user experience
- **Responsive Design**: Beautiful, modern UI with Tailwind CSS
- **Scalable Architecture**: Built with best practices and clean code patterns

## Tech Stack

- **Ruby on Rails 8.0.2**: Backend framework
- **PostgreSQL**: Database
- **Hotwire (Turbo + Stimulus)**: Frontend interactivity
- **Slim**: Template engine
- **Tailwind CSS 4**: Styling
- **Devise**: Authentication

## Getting Started

### Prerequisites

- Ruby 3.3.0 or higher
- PostgreSQL 13 or higher
- Node.js (for JavaScript dependencies)

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd boramarcar
```

2. Install dependencies:

```bash
bundle install
```

3. Configure environment variables:

```bash
cp .env.example .env
# Edit .env with your database credentials if needed
```

4. Setup the database:

```bash
# Make sure PostgreSQL is running
sudo service postgresql start

# Create and setup the database
rails db:create
rails db:migrate
rails db:seed
```

5. Start the development server:

```bash
bin/dev
```

6. Visit http://localhost:3000

### Sample Accounts

The seed data creates the following test accounts:

- alice@example.com (password: password123)
- bob@example.com (password: password123)
- carol@example.com (password: password123)
- dave@example.com (password: password123)

## How to Use

### Creating a Group

1. Sign in to your account
2. Click "Create New Group"
3. Fill in the group name and description
4. Choose if the group should be public (anyone can join) or private
5. Click "Create Group"

### Adding Your Availability

1. Go to a group's detail page
2. In the "Add Your Availability" section:
   - Select a start date
   - Select an end date (or leave the same for a single day)
3. Click "Add Availability"
4. Your availability will appear instantly using Turbo Streams

### Viewing Results

1. Click "See Results" on any group
2. View dates ranked by availability percentage
3. Dates with 100% availability are highlighted as "PERFECT MATCH"
4. Expand each date to see who's available
5. Dates are sorted by:
   - Number of people available (descending)
   - Date (ascending)

### Group Types

**Private Groups:**

- Only members can see and join
- Perfect for family gatherings or close friend groups

**Public Groups:**

- Anyone can see and join
- Great for community events or open meetups

## Database Schema

### Users

- Email, encrypted password (via Devise)
- Has many groups (through memberships)
- Has many owned groups
- Has many availabilities

### Groups

- Name, description, is_public flag
- Belongs to owner (User)
- Has many members through group_memberships
- Has many availabilities

### GroupMemberships

- Join table between Users and Groups
- Ensures one membership per user per group

### Availabilities

- Start date and end date
- Belongs to User and Group
- Supports both single days and date ranges

## Key Algorithms

### Date Matching Algorithm

Located in `app/controllers/groups_controller.rb:87-108`

The algorithm:

1. Collects all availability records for the group
2. Expands each availability into individual dates
3. Groups dates by user count
4. Calculates percentage availability
5. Sorts by count (descending) then date (ascending)
6. Returns comprehensive analysis including:
   - Date
   - Available users
   - Count and percentage
   - Perfect match indicator (100% availability)

## Project Structure

```
app/
├── controllers/
│   ├── groups_controller.rb      # Main group CRUD and results
│   └── availabilities_controller.rb  # Availability management
├── models/
│   ├── user.rb                    # User with Devise
│   ├── group.rb                   # Group with associations
│   ├── group_membership.rb        # Join model
│   └── availability.rb            # Availability with validations
└── views/
    ├── groups/                    # Group views (Slim)
    │   ├── index.html.slim
    │   ├── show.html.slim
    │   ├── new.html.slim
    │   ├── edit.html.slim
    │   └── results.html.slim
    ├── availabilities/            # Turbo Stream responses
    │   ├── create.turbo_stream.slim
    │   └── destroy.turbo_stream.slim
    └── layouts/
        └── application.html.slim  # Main layout with nav
```

## Future Enhancements

Potential features for scaling:

- Email notifications for new group invitations
- Calendar integration (Google Calendar, iCal)
- Mobile app (React Native or Flutter)
- Advanced filtering (by location, time of day)
- Recurring availability patterns
- Export results to PDF
- Group chat functionality
- User profiles with timezones

## Testing

To run tests:

```bash
rails test
```

## Deployment

The application is containerized with Docker and configured for deployment with Kamal.

For Heroku deployment:

```bash
heroku create
heroku addons:create heroku-postgresql
git push heroku main
heroku run rails db:migrate
heroku run rails db:seed
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Author

Built with care following Ruby on Rails best practices and clean code patterns.
