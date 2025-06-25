# SplitMySub

SplitMySub is a modern subscription splitting application that helps you share and manage recurring subscriptions with friends, family, or colleagues. Built with Ruby on Rails and Svelte for a seamless user experience.

![localhost_3100_login (1)](https://github.com/user-attachments/assets/e3d98e5c-6e4b-4d64-a5d3-e31209459f07)



## Features

- **Subscription Management** - Create and manage shared subscriptions with detailed billing cycles
- **Smart Splitting** - Automatically calculate and split costs among group members
- **Payment Tracking** - Track payments and send automated reminders
- **Invitation System** - Easily invite friends and family to join subscriptions
- **Evidence Upload** - Upload payment receipts and proof of subscription costs
- **Email Notifications** - Automated reminders and payment notifications
- **Modern UI** - Built with Svelte and ShadcnUI for a smooth user experience
- **Secure Authentication** - Magic link authentication for easy and secure access

## Installation

### Local Development

1. Clone the repository:
   ```sh
   git clone <repository-url> splitmysub
   cd splitmysub
   ```
2. Install dependencies:
   ```sh
   bundle install
   npm install
   ```
3. Setup the database:
   ```sh
   rails db:setup
   ```
4. Start the development server:
   ```sh
   bin/dev
   ```
5. Open in browser at localhost:3100

### Docker Development

1. Clone the repository:
   ```sh
   git clone <repository-url> splitmysub
   cd splitmysub
   ```
2. Start with docker-compose:
   ```sh
   # For development (with live code reloading)
   docker-compose -f docker-compose.dev.yml up --build
   
   # For production-like environment
   docker-compose up --build
   ```
3. Open in browser at localhost:3000

### Docker Production

1. Build the production image:
   ```sh
   docker build -t splitmysub .
   ```
2. Run the container:
   ```sh
   docker run -d -p 80:80 \
     -e RAILS_MASTER_KEY=<your-master-key> \
     -v splitmysub_storage:/rails/storage \
-v splitmysub_db:/rails/db \
--name splitmysub splitmysub
   ```

### Deployment with Kamal

This application is configured for deployment with [Kamal](https://kamal-deploy.org/):

1. Configure your servers in `config/deploy.yml`
2. Set up your secrets in `.kamal/secrets`
3. Deploy:
   ```sh
   kamal setup
   kamal deploy
   ```

## Usage

SplitMySub makes it easy to share subscription costs:

1. **Create a Project** - Set up a new subscription (Netflix, Spotify, etc.)
2. **Invite Members** - Send invitations to friends or family
3. **Track Payments** - Upload receipts and track who has paid
4. **Get Reminders** - Automated email reminders for upcoming payments
5. **Split Costs** - Automatically calculate each person's share

## Contributing

Feel free to fork this repository and submit pull requests with improvements, fixes, or additional features.

## License

This project is open-source and available under the [MIT License](LICENSE).

