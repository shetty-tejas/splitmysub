# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "🌱 Starting SplitMySub seed data creation..."

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Clearing existing data..."
  Payment.destroy_all
  BillingCycle.destroy_all
  ProjectMembership.destroy_all
  Invitation.destroy_all
  Project.destroy_all
  User.destroy_all
  puts "✅ Existing data cleared"
end

# Create Users
puts "👥 Creating users..."

users = [
  {
    email_address: "testuser@example.com",
    first_name: "Test",
    last_name: "User",
    preferences: { notifications: true, theme: "light" }
  },
  {
    email_address: "john.doe@example.com",
    first_name: "John",
    last_name: "Doe",
    preferences: { notifications: true, theme: "light" }
  },
  {
    email_address: "jane.smith@example.com",
    first_name: "Jane",
    last_name: "Smith",
    preferences: { notifications: true, theme: "dark" }
  },
  {
    email_address: "mike.johnson@example.com",
    first_name: "Mike",
    last_name: "Johnson",
    preferences: { notifications: false, theme: "light" }
  },
  {
    email_address: "sarah.wilson@example.com",
    first_name: "Sarah",
    last_name: "Wilson",
    preferences: { notifications: true, theme: "auto" }
  },
  {
    email_address: "alex.brown@example.com",
    first_name: "Alex",
    last_name: "Brown",
    preferences: { notifications: true, theme: "light" }
  },
  {
    email_address: "emily.davis@example.com",
    first_name: "Emily",
    last_name: "Davis",
    preferences: { notifications: false, theme: "dark" }
  },
  {
    email_address: "chris.taylor@example.com",
    first_name: "Chris",
    last_name: "Taylor",
    preferences: { notifications: true, theme: "light" }
  },
  {
    email_address: "lisa.anderson@example.com",
    first_name: "Lisa",
    last_name: "Anderson",
    preferences: { notifications: true, theme: "auto" }
  }
]

created_users = users.map do |user_attrs|
  User.find_or_create_by!(email_address: user_attrs[:email_address]) do |user|
    user.first_name = user_attrs[:first_name]
    user.last_name = user_attrs[:last_name]
    user.preferences = user_attrs[:preferences]
  end
end

puts "✅ Created #{created_users.count} users"

# Create Projects
puts "📁 Creating projects..."

projects_data = [
  {
    name: "Netflix Premium",
    description: "Family Netflix Premium subscription for 4K streaming and multiple screens",
    cost: 19.99,
    billing_cycle: "monthly",
    renewal_date: 1.month.from_now,
    reminder_days: 7,
    subscription_url: "https://netflix.com",
    payment_instructions: "Please pay via Venmo @john-doe or PayPal john.doe@example.com",
    owner: created_users[1], # John (now index 1)
    members: [ created_users[0], created_users[2], created_users[3], created_users[4] ] # Test User, Jane, Mike, Sarah
  },
  {
    name: "Spotify Family",
    description: "Spotify Family plan for up to 6 accounts with premium features",
    cost: 15.99,
    billing_cycle: "monthly",
    renewal_date: 2.weeks.from_now,
    reminder_days: 5,
    subscription_url: "https://spotify.com",
    payment_instructions: "Zelle: jane.smith@example.com or Cash App: $janesmith",
    owner: created_users[2], # Jane (now index 2)
    members: [ created_users[0], created_users[1], created_users[5], created_users[6] ] # Test User, John, Alex, Emily
  },
  {
    name: "Adobe Creative Cloud",
    description: "Adobe Creative Cloud All Apps subscription for design work",
    cost: 52.99,
    billing_cycle: "monthly",
    renewal_date: 3.weeks.from_now,
    reminder_days: 10,
    subscription_url: "https://adobe.com",
    payment_instructions: "PayPal: mike.johnson@example.com or bank transfer (ask for details)",
    owner: created_users[3], # Mike (now index 3)
    members: [ created_users[7], created_users[8] ] # Chris, Lisa
  },
  {
    name: "Disney+ Bundle",
    description: "Disney+ Hulu ESPN+ bundle subscription",
    cost: 24.99,
    billing_cycle: "monthly",
    renewal_date: 10.days.from_now,
    reminder_days: 3,
    subscription_url: "https://disneyplus.com",
    payment_instructions: "Venmo @sarah-wilson or Apple Pay",
    owner: created_users[4], # Sarah (now index 4)
    members: [ created_users[0], created_users[1], created_users[2] ] # Test User, John, Jane
  },
  {
    name: "Microsoft 365 Family",
    description: "Microsoft 365 Family subscription with Office apps and OneDrive storage",
    cost: 99.99,
    billing_cycle: "yearly",
    renewal_date: 6.months.from_now,
    reminder_days: 14,
    subscription_url: "https://microsoft.com",
    payment_instructions: "Bank transfer or PayPal alex.brown@example.com",
    owner: created_users[5], # Alex (now index 5)
    members: [ created_users[3], created_users[6], created_users[7], created_users[8] ] # Mike, Emily, Chris, Lisa
  },
  {
    name: "YouTube Premium",
    description: "YouTube Premium for ad-free videos and YouTube Music",
    cost: 11.99,
    billing_cycle: "monthly",
    renewal_date: 1.week.from_now,
    reminder_days: 2,
    subscription_url: "https://youtube.com",
    payment_instructions: "Cash App $emilydavis or Zelle",
    owner: created_users[6], # Emily (now index 6)
    members: [ created_users[4], created_users[5] ] # Sarah, Alex
  },
  {
    name: "Dropbox Business",
    description: "Dropbox Business subscription for team file storage and collaboration",
    cost: 180.00,
    billing_cycle: "yearly",
    renewal_date: 8.months.from_now,
    reminder_days: 21,
    subscription_url: "https://dropbox.com",
    payment_instructions: "Company credit card reimbursement - submit receipts to chris.taylor@example.com",
    owner: created_users[7], # Chris (now index 7)
    members: [ created_users[1], created_users[2], created_users[3], created_users[8] ] # John, Jane, Mike, Lisa
  },
  {
    name: "Canva Pro Team",
    description: "Canva Pro team subscription for design collaboration",
    cost: 44.99,
    billing_cycle: "quarterly",
    renewal_date: 2.months.from_now,
    reminder_days: 7,
    subscription_url: "https://canva.com",
    payment_instructions: "PayPal lisa.anderson@example.com or Venmo @lisa-anderson",
    owner: created_users[8], # Lisa (now index 8)
    members: [ created_users[3], created_users[7] ] # Mike, Chris
  },
  {
    name: "Hulu + Live TV",
    description: "Hulu with Live TV subscription for streaming and live television",
    cost: 76.99,
    billing_cycle: "monthly",
    renewal_date: 3.weeks.from_now,
    reminder_days: 5,
    subscription_url: "https://hulu.com",
    payment_instructions: "Please pay via PayPal testuser@example.com or Venmo @testuser",
    owner: created_users[0], # Test User
    members: [ created_users[1], created_users[2], created_users[4] ] # John, Jane, Sarah
  }
]

created_projects = []

projects_data.each do |project_data|
  project = Project.find_or_create_by!(
    name: project_data[:name],
    user: project_data[:owner]
  ) do |p|
    p.description = project_data[:description]
    p.cost = project_data[:cost]
    p.billing_cycle = project_data[:billing_cycle]
    p.renewal_date = project_data[:renewal_date]
    p.reminder_days = project_data[:reminder_days]
    p.subscription_url = project_data[:subscription_url]
    p.payment_instructions = project_data[:payment_instructions]
  end

  # Add project members
  project_data[:members].each do |member|
    ProjectMembership.find_or_create_by!(
      user: member,
      project: project
    ) do |membership|
      membership.role = "member"
    end
  end

  created_projects << project
end

puts "✅ Created #{created_projects.count} projects with memberships"

# Create Billing Cycles
puts "💰 Creating billing cycles..."

billing_cycles_created = 0

created_projects.each do |project|
  # Create past billing cycles (for history) - skip validation for seed data
  case project.billing_cycle
  when "monthly"
    # Create 3 past monthly cycles
    3.times do |i|
      due_date = (i + 1).months.ago.beginning_of_month + project.renewal_date.day.days - 1.day
      next if due_date > Date.current

      cycle = BillingCycle.find_or_initialize_by(
        project: project,
        due_date: due_date
      )

      unless cycle.persisted?
        cycle.total_amount = project.cost
        cycle.save!(validate: false) # Skip validation for past dates in seed data
        billing_cycles_created += 1
      end
    end

    # Create current/upcoming cycle
    current_due = project.renewal_date
    BillingCycle.find_or_create_by!(
      project: project,
      due_date: current_due
    ) do |cycle|
      cycle.total_amount = project.cost
    end
    billing_cycles_created += 1

  when "quarterly"
    # Create 2 past quarterly cycles
    2.times do |i|
      due_date = ((i + 1) * 3).months.ago.beginning_of_quarter + project.renewal_date.day.days - 1.day
      next if due_date > Date.current

      cycle = BillingCycle.find_or_initialize_by(
        project: project,
        due_date: due_date
      )

      unless cycle.persisted?
        cycle.total_amount = project.cost
        cycle.save!(validate: false) # Skip validation for past dates in seed data
        billing_cycles_created += 1
      end
    end

    # Create current/upcoming cycle
    BillingCycle.find_or_create_by!(
      project: project,
      due_date: project.renewal_date
    ) do |cycle|
      cycle.total_amount = project.cost
    end
    billing_cycles_created += 1

  when "yearly"
    # Create 1 past yearly cycle
    due_date = 1.year.ago.beginning_of_year + project.renewal_date.day.days - 1.day
    if due_date <= Date.current
      cycle = BillingCycle.find_or_initialize_by(
        project: project,
        due_date: due_date
      )

      unless cycle.persisted?
        cycle.total_amount = project.cost
        cycle.save!(validate: false) # Skip validation for past dates in seed data
        billing_cycles_created += 1
      end
    end

    # Create current/upcoming cycle
    BillingCycle.find_or_create_by!(
      project: project,
      due_date: project.renewal_date
    ) do |cycle|
      cycle.total_amount = project.cost
    end
    billing_cycles_created += 1
  end
end

puts "✅ Created #{billing_cycles_created} billing cycles"

# Create Payments
puts "💳 Creating payments..."

payments_created = 0

BillingCycle.includes(project: [ :user, :members ]).each do |cycle|
  project = cycle.project
  all_members = [ project.user ] + project.members.to_a
  expected_amount = project.cost_per_member

  # For past cycles, create mostly complete payments
  if cycle.due_date < Date.current
    all_members.each_with_index do |member, index|
      # 90% chance of payment for past cycles
      next if rand > 0.9

      status = [ "confirmed", "confirmed", "confirmed", "rejected" ].sample
      amount = case rand
      when 0..0.7 then expected_amount # Exact amount
      when 0.7..0.9 then [ expected_amount + rand(2.0).round(2), expected_amount * 1.5 ].min # Slightly over but within limits
      else [ expected_amount - rand(1.0).round(2), 0.01 ].max # Slightly under but positive
      end

      payment = Payment.find_or_create_by!(
        billing_cycle: cycle,
        user: member
      ) do |p|
        p.amount = amount
        p.status = status
        p.confirmation_date = status == "confirmed" ? cycle.due_date - rand(10).days : nil
        p.confirmed_by = status == "confirmed" ? project.user : nil
        p.notes = [ "Paid via Venmo", "PayPal transfer", "Cash payment", "Bank transfer", "" ].sample
        p.transaction_id = status == "confirmed" ? "TXN#{rand(100000..999999)}" : nil
      end

      payments_created += 1
    end

  # For current/future cycles, create some pending payments
  else
    all_members.each_with_index do |member, index|
      # 60% chance of payment for current/future cycles
      next if rand > 0.6

      status = [ "pending", "pending", "confirmed", "pending" ].sample
      amount = case rand
      when 0..0.8 then expected_amount # Exact amount
      when 0.8..0.95 then [ expected_amount + rand(2.0).round(2), expected_amount * 1.5 ].min # Slightly over but within limits
      else [ expected_amount - rand(1.0).round(2), 0.01 ].max # Slightly under but positive
      end

      payment = Payment.find_or_create_by!(
        billing_cycle: cycle,
        user: member
      ) do |p|
        p.amount = amount
        p.status = status
        p.confirmation_date = status == "confirmed" ? Date.current - rand(5).days : nil
        p.confirmed_by = status == "confirmed" ? project.user : nil
        p.notes = [ "Will pay this weekend", "Paid via Venmo - pending confirmation", "PayPal sent", "" ].sample
        p.transaction_id = status == "confirmed" ? "TXN#{rand(100000..999999)}" : nil
      end

      payments_created += 1
    end
  end
end

puts "✅ Created #{payments_created} payments"

# Create some Invitations
puts "📧 Creating invitations..."

invitations_data = [
  {
    project: created_projects[0], # Netflix
    email: "newuser1@example.com",
    invited_by: created_users[1], # John
    status: "pending"
  },
  {
    project: created_projects[1], # Spotify
    email: "newuser2@example.com",
    invited_by: created_users[2], # Jane
    status: "pending"
  },
  {
    project: created_projects[2], # Adobe
    email: "designer@example.com",
    invited_by: created_users[3], # Mike
    status: "expired"
  },
  {
    project: created_projects[4], # Microsoft 365
    email: "teamlead@example.com",
    invited_by: created_users[5], # Alex
    status: "declined"
  },
  {
    project: created_projects[8], # Test User's Hulu project
    email: "friend@example.com",
    invited_by: created_users[0], # Test User
    status: "pending"
  }
]

invitations_created = 0

invitations_data.each do |invitation_data|
  invitation = Invitation.find_or_initialize_by(
    project: invitation_data[:project],
    email: invitation_data[:email]
  )

  unless invitation.persisted?
    invitation.invited_by = invitation_data[:invited_by]
    invitation.status = invitation_data[:status]
    invitation.role = "member"
    invitation.token = SecureRandom.urlsafe_base64(32)
    invitation.expires_at = case invitation_data[:status]
    when "expired" then 1.week.ago
    when "declined" then 3.days.from_now
    else 1.week.from_now
    end

    # Skip validation for expired invitations in seed data
    if invitation_data[:status] == "expired"
      invitation.save!(validate: false)
    else
      invitation.save!
    end

    invitations_created += 1
  end
end

puts "✅ Created #{invitations_created} invitations"

# Create some Reminder Schedules
puts "⏰ Creating reminder schedules..."

reminder_schedules_created = 0

created_projects.each do |project|
  # Create default reminder schedule
  [ 7, 3, 1 ].each_with_index do |days_before, index|
    ReminderSchedule.find_or_create_by!(
      project: project,
      days_before: days_before,
      escalation_level: index + 1 # Start from 1, not 0
    )
    reminder_schedules_created += 1
  end
end

puts "✅ Created #{reminder_schedules_created} reminder schedules"

# Print summary
puts "\n🎉 Seed data creation completed!"
puts "=" * 50
puts "📊 Summary:"
puts "👥 Users: #{User.count}"
puts "📁 Projects: #{Project.count}"
puts "🤝 Project Memberships: #{ProjectMembership.count}"
puts "💰 Billing Cycles: #{BillingCycle.count}"
puts "💳 Payments: #{Payment.count}"
puts "📧 Invitations: #{Invitation.count}"
puts "⏰ Reminder Schedules: #{ReminderSchedule.count}"
puts "=" * 50

# Print some useful information for testing
puts "\n🔍 Test Data Overview:"
puts "=" * 50

puts "\n👤 Sample Users:"
puts "  🧪 #{created_users[0].full_name} (#{created_users[0].email_address}) - TEST USER"
created_users[1..3].each do |user|
  puts "  • #{user.full_name} (#{user.email_address})"
end

puts "\n📁 Sample Projects:"
created_projects.first(3).each do |project|
  puts "  • #{project.name} - $#{project.cost}/#{project.billing_cycle}"
  puts "    Owner: #{project.user.full_name}"
  puts "    Members: #{project.members.count}"
  puts "    Next due: #{project.renewal_date}"
end

puts "\n💰 Payment Status Summary:"
total_cycles = BillingCycle.count
paid_cycles = BillingCycle.joins(:payments).where(payments: { status: "confirmed" }).distinct.count
pending_cycles = BillingCycle.joins(:payments).where(payments: { status: "pending" }).distinct.count

puts "  • Total billing cycles: #{total_cycles}"
puts "  • Cycles with confirmed payments: #{paid_cycles}"
puts "  • Cycles with pending payments: #{pending_cycles}"
puts "  • Total payments: #{Payment.count}"
puts "    - Confirmed: #{Payment.confirmed.count}"
puts "    - Pending: #{Payment.pending.count}"
puts "    - Rejected: #{Payment.rejected.count}"

puts "\n🚀 Ready to test SplitMySub!"
puts "🧪 Use testuser@example.com for testing (owns Hulu + Live TV project)"
puts "You can also log in with any of the other seeded user emails."
puts "=" * 50
