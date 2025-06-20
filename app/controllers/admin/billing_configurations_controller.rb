class Admin::BillingConfigurationsController < Admin::BaseController
  before_action :set_billing_config, only: [ :show, :edit, :update, :reset ]

  # GET /admin/billing_configuration
  def show
    render inertia: "admin/BillingConfiguration/Show", props: {
      config: billing_config_props(@billing_config),
      validation_errors: [],
      supported_frequencies: supported_frequencies_options,
      frequency_descriptions: frequency_descriptions,
      preview_data: {
        generation_end_date: Date.current + 3.months,
        archiving_cutoff_date: Date.current - 6.months,
        next_reminder_dates: [],
        affected_cycles_count: { total_cycles: 0, archivable_cycles: 0, due_soon_cycles: 0 }
      }
    }
  end

  # GET /admin/billing_configuration/edit
  def edit
    render inertia: "admin/BillingConfiguration/Edit", props: {
      config: billing_config_props(@billing_config),
      supported_frequencies: supported_frequencies_options,
      frequency_descriptions: frequency_descriptions,
      validation_errors: []
    }
  end

  # PATCH/PUT /admin/billing_configuration
  def update
    if @billing_config.update(billing_config_params)
      redirect_to admin_billing_configuration_path,
                  notice: "Billing configuration updated successfully."
    else
      render inertia: "admin/BillingConfiguration/Edit", props: {
        config: billing_config_props(@billing_config),
        supported_frequencies: supported_frequencies_options,
        frequency_descriptions: frequency_descriptions,
        validation_errors: format_validation_errors(@billing_config.errors)
      }
    end
  end

  # POST /admin/billing_configuration/reset
  def reset
    @billing_config.destroy
    new_config = BillingConfig.create_default!

    redirect_to admin_billing_configuration_path,
                notice: "Billing configuration reset to defaults successfully."
  end



  private

  def set_billing_config
    @billing_config = BillingConfig.current
  end

  def billing_config_params
    params.require(:billing_config).permit(
      :generation_months_ahead,
      :archiving_months_threshold,
      :due_soon_days,
      :auto_archiving_enabled,
      :auto_generation_enabled,
      :payment_grace_period_days,
      :reminders_enabled,
      :gentle_reminder_days_before,
      :standard_reminder_days_overdue,
      :urgent_reminder_days_overdue,
      :final_notice_days_overdue,
      :default_frequency,
      default_billing_frequencies: [],
      supported_billing_frequencies: [],
      reminder_schedule: []
    )
  end

  def billing_config_props(config)
    {
      id: config.id,
      generation_months_ahead: config.generation_months_ahead,
      archiving_months_threshold: config.archiving_months_threshold,
      due_soon_days: config.due_soon_days,
      auto_archiving_enabled: config.auto_archiving_enabled,
      auto_generation_enabled: config.auto_generation_enabled,
      payment_grace_period_days: config.payment_grace_period_days,
      default_billing_frequencies: config.default_billing_frequencies,
      supported_billing_frequencies: config.supported_billing_frequencies,
      reminder_schedule: config.reminder_schedule,
      reminders_enabled: config.reminders_enabled,
      gentle_reminder_days_before: config.gentle_reminder_days_before,
      standard_reminder_days_overdue: config.standard_reminder_days_overdue,
      urgent_reminder_days_overdue: config.urgent_reminder_days_overdue,
      final_notice_days_overdue: config.final_notice_days_overdue,
      default_frequency: config.default_frequency,
      created_at: config.created_at,
      updated_at: config.updated_at
    }
  end

  def supported_frequencies_options
    [
      { value: "weekly", label: "Weekly", description: "Every 7 days" },
      { value: "monthly", label: "Monthly", description: "Every month on the same date" },
      { value: "quarterly", label: "Quarterly", description: "Every 3 months" },
      { value: "yearly", label: "Yearly", description: "Every 12 months" }
    ]
  end

  def frequency_descriptions
    {
      "weekly" => "Billing occurs every 7 days from the start date",
      "monthly" => "Billing occurs on the same day each month",
      "quarterly" => "Billing occurs every 3 months (seasonal)",
      "yearly" => "Billing occurs once per year (annual subscriptions)"
    }
  end

  def format_validation_errors(errors)
    errors.full_messages.map do |message|
      {
        field: errors.attribute_names.first&.to_s,
        message: message
      }
    end
  end

  def calculate_preview_data
    # Calculate preview data for the current configuration
    begin
      {
        generation_end_date: @billing_config.generation_end_date,
        archiving_cutoff_date: @billing_config.archiving_cutoff_date,
        next_reminder_dates: calculate_preview_reminder_dates,
        affected_cycles_count: calculate_affected_cycles_count
      }
    rescue => e
      Rails.logger.error "Error calculating preview data: #{e.message}"
      {
        generation_end_date: Date.current + 3.months,
        archiving_cutoff_date: Date.current - 6.months,
        next_reminder_dates: [],
        affected_cycles_count: { total_cycles: 0, archivable_cycles: 0, due_soon_cycles: 0 }
      }
    end
  end

  def calculate_preview_reminder_dates
    # Calculate next few reminder dates based on current settings
    base_date = Date.current
    (@billing_config.reminder_schedule || [ 7, 3, 1 ]).map do |days_before|
      base_date + days_before.days
    end
  end

  def calculate_affected_cycles_count
    # Count how many existing cycles would be affected by configuration changes
    {
      total_cycles: BillingCycle.count,
      archivable_cycles: BillingCycle.where(archived: false)
                                    .where("due_date < ?", @billing_config.archiving_cutoff_date)
                                    .count,
      due_soon_cycles: BillingCycle.where(archived: false)
                                   .where(due_date: Date.current..@billing_config.due_soon_days.days.from_now)
                                   .count
    }
  end

  def generate_warnings(config)
    warnings = []

    if config.archiving_months_threshold < 3
      warnings << "Short archiving threshold may result in premature archiving of recent cycles"
    end

    if config.generation_months_ahead > 6
      warnings << "Generating too far ahead may create unnecessary cycles"
    end

    if config.gentle_reminder_days_before < 1
      warnings << "Very short reminder period may not give users enough notice"
    end

    warnings
  end
end
