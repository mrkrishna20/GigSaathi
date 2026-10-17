class AssistantController < ApplicationController
  LANGUAGES = {
    "english" => "English",
    "hindi" => "Hindi",
    "hinglish" => "Hinglish (Hindi written in Latin script with English)"
  }.freeze

  def index
    @language = "english"
  end

  def ask
    @question = sanitize_field(params[:question])
    @language = normalize_language(params[:language])

    if @question.blank? || @question.length > 2_000 || !LANGUAGES.key?(@language)
      @error = "Enter a question (up to 2,000 characters) and choose a supported language."
      render :index, status: :unprocessable_entity
      return
    end

    @answer = AssistantResponseGenerator.call(question: @question, language: LANGUAGES.fetch(@language))
    render :index
  rescue LlmClient::ConfigurationError => error
    Rails.logger.warn("Assistant is not configured: #{error.message}")
    @error = error.message
    render :index, status: :service_unavailable
  rescue LlmClient::RequestError => error
    Rails.logger.error("Assistant request failed: #{error.message}")
    @error = "The AI assistant could not respond right now. Please try again later."
    render :index, status: :service_unavailable
  end

  private

  def sanitize_field(value)
    value.to_s.strip.gsub(/[[:cntrl:]]+/, " ")
  end

  def normalize_language(value)
    value.to_s.strip.downcase
  end
end
