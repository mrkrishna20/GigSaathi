class ComplaintsController < ApplicationController
  rate_limit to: 20, within: 3.minutes, scope: :llm_generation, only: :create, with: :ai_rate_limit_exceeded

  CATEGORIES = {
    "delayed_payment" => "Delayed payment",
    "unfair_deduction" => "Unfair deduction",
    "account_deactivation" => "Account deactivation",
    "other_work_issue" => "Other work-related issue"
  }.freeze

  def new
    @language = "english"
  end

  def create
    @category = params[:category].to_s.strip
    @company_name = sanitize_field(params[:company_name])
    @description = sanitize_field(params[:description])
    @language = params[:language].to_s.strip.downcase

    unless CATEGORIES.key?(@category) && %w[english hindi].include?(@language) &&
           @description.present? && @description.length <= 4_000 && @company_name.length <= 100
      @error = "Choose a category and language, and describe your issue (up to 4,000 characters)."
      render :new, status: :unprocessable_entity
      return
    end

    @complaint = ComplaintGenerator.call(
      category: CATEGORIES.fetch(@category),
      company_name: @company_name,
      description: @description,
      language: @language == "hindi" ? "Hindi" : "English"
    )
    render :new
  rescue LlmClient::ConfigurationError => error
    Rails.logger.warn("Complaint generator is not configured: #{error.message}")
    @error = error.message
    render :new, status: :service_unavailable
  rescue LlmClient::RequestError => error
    Rails.logger.error("Complaint generation failed: #{error.message}")
    @error = "A complaint could not be generated right now. Please try again later."
    render :new, status: :service_unavailable
  end

  private

  def sanitize_field(value)
    value.to_s.strip.gsub(/[[:cntrl:]]+/, " ")
  end

  def ai_rate_limit_exceeded
    @language = "english"
    @error = "Too many AI requests. Please wait a few minutes and try again."
    render :new, status: :too_many_requests
  end
end
