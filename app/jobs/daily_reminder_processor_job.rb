class DailyReminderProcessorJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting daily reminder processing at #{Time.current}"

    begin
      # Process all reminders for projects with upcoming billing cycles
      ReminderService.process_all_reminders

      Rails.logger.info "Completed daily reminder processing at #{Time.current}"
    rescue StandardError => e
      Rails.logger.error "Daily reminder processing failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
