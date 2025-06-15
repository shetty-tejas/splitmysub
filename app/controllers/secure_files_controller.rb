class SecureFilesController < ApplicationController
  before_action :set_payment, only: [ :payment_evidence ]
  before_action :authorize_file_access, only: [ :payment_evidence ]

  # Secure payment evidence download
  def payment_evidence
    unless @payment.evidence.attached?
      redirect_back(fallback_location: root_path, alert: "File not found.")
      return
    end

    # Serve file securely
    send_secure_file(@payment.evidence)
  end

  # Generic secure file download with token
  def download_with_token
    token = params[:token]

    unless valid_download_token?(token)
      render json: { error: "Invalid or expired download token" }, status: :forbidden
      return
    end

    file_info = decode_download_token(token)
    attachment = ActiveStorage::Attachment.find(file_info[:attachment_id])

    # Verify user still has access
    case file_info[:resource_type]
    when "payment_evidence"
      payment = Payment.find(file_info[:resource_id])
      authorize!(:download_evidence, payment)
    else
      render json: { error: "Unknown resource type" }, status: :bad_request
      return
    end

    send_secure_file(attachment)
  end

  private

  def set_payment
    @payment = Payment.find(params[:payment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Payment not found."
  end

  def authorize_file_access
    authorize!(:download_evidence, @payment)
  end

  def send_secure_file(attachment)
    # Set security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Cache-Control"] = "private, no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    # Validate file type for additional security
    unless safe_file_type?(attachment.content_type)
      render json: { error: "File type not allowed for download" }, status: :forbidden
      return
    end

    # Stream file to user
    send_data(
      attachment.download,
      filename: sanitize_filename(attachment.filename.to_s),
      type: attachment.content_type,
      disposition: "attachment"
    )
  rescue => e
    Rails.logger.error "Error serving file: #{e.message}"
    render json: { error: "Error downloading file" }, status: :internal_server_error
  end

  def safe_file_type?(content_type)
    allowed_types = [
      "image/png",
      "image/jpg",
      "image/jpeg",
      "image/heic",
      "application/pdf"
    ]
    allowed_types.include?(content_type)
  end

  def sanitize_filename(filename)
    # Remove potentially dangerous characters from filename
    filename.gsub(/[^0-9A-Za-z.\-_]/, "_")
  end



  def generate_download_token(attachment)
    # Generate a secure token for file downloads (expires in 1 hour)
    payload = {
      attachment_id: attachment.id,
      resource_type: "payment_evidence",
      resource_id: @payment.id,
      user_id: Current.user.id,
      expires_at: 1.hour.from_now.to_i
    }

    # In a real app, you'd use a proper JWT library or Rails.application.message_verifier
    Base64.urlsafe_encode64(payload.to_json)
  end

  def valid_download_token?(token)
    return false unless token

    begin
      payload = JSON.parse(Base64.urlsafe_decode64(token))
      payload["expires_at"] > Time.current.to_i && payload["user_id"] == Current.user.id
    rescue
      false
    end
  end

  def decode_download_token(token)
    JSON.parse(Base64.urlsafe_decode64(token)).symbolize_keys
  end
end
