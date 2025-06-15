# Configure secure file storage
Rails.application.configure do
  # Use secure storage for payment evidence in production
  if Rails.env.production?
    config.active_storage.variant_processor = :mini_magick

    # Configure secure storage paths
    config.after_initialize do
      # Ensure secure storage directory exists and has proper permissions
      secure_storage_path = Rails.root.join("storage", "secure")
      FileUtils.mkdir_p(secure_storage_path) unless Dir.exist?(secure_storage_path)

      # Set restrictive permissions (owner read/write only)
      File.chmod(0700, secure_storage_path) if File.exist?(secure_storage_path)
    end
  end
end

# Configure file size limits and allowed types
Rails.application.configure do
  # Set variant processor for image processing
  config.active_storage.variant_processor = :mini_magick if Rails.env.production?
end

# Add file validation to Payment model
Rails.application.config.to_prepare do
  Payment.class_eval do
    # Validate evidence file if attached
    validate :evidence_file_validation, if: -> { evidence.attached? }

    private

    def evidence_file_validation
      return unless evidence.attached?

      # Check file size (5MB limit)
      if evidence.byte_size > 5.megabytes
        errors.add(:evidence, "File size must be less than 5MB")
      end

      # Check file type
      allowed_types = [ "image/png", "image/jpg", "image/jpeg", "image/heic", "application/pdf" ]
      unless allowed_types.include?(evidence.content_type)
        errors.add(:evidence, "File type must be PNG, JPG, HEIC, or PDF")
      end

      # Check for malicious content (basic check)
      if evidence.filename.to_s.include?("..")
        errors.add(:evidence, "Invalid filename")
      end
    end
  end
end
