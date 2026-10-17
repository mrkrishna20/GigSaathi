class AssistantController < ApplicationController
  rate_limit to: 20, within: 3.minutes, scope: :llm_generation, only: :ask, with: :ai_rate_limit_exceeded

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
    @history = parse_history

    if @question.blank? || @question.length > 2_000 || !LANGUAGES.key?(@language) || @history.nil?
      @error ||= "Enter a question (up to 2,000 characters), choose a supported language, and keep chat history under 8,000 characters."
      respond_with_error(:unprocessable_entity)
      return
    end

    @answer = AssistantResponseGenerator.call(
      question: @question,
      language: LANGUAGES.fetch(@language),
      history: @history
    )
    respond_to do |format|
      format.html { render :index }
      format.json { render json: { question: @question, answer: @answer } }
    end
  rescue LlmClient::ConfigurationError => error
    Rails.logger.warn("Assistant is not configured: #{error.message}")
    @error = error.message
    respond_with_error(:service_unavailable)
  rescue LlmClient::ConnectionError => error
    Rails.logger.error("Assistant provider connection failed: #{error.message}")
    @error = "GigSaathi could not connect to the AI provider. Check the server's internet, DNS, firewall, or proxy access to your configured LLM_API_URL, then try again."
    respond_with_error(:service_unavailable)
  rescue LlmClient::RequestError => error
    Rails.logger.error("Assistant request failed: #{error.message}")
    @error = if error.message.include?("HTTP 401") || error.message.include?("HTTP 403")
      "The AI provider rejected the API key. Check that your Groq key is valid and set as GROQ_API_KEY or LLM_API_KEY in .env."
    else
      "The AI assistant could not respond right now. Please try again later."
    end
    respond_with_error(:service_unavailable)
  end

  private

  def sanitize_field(value)
    value.to_s.strip.gsub(/[[:cntrl:]]+/, " ")
  end

  def normalize_language(value)
    value.to_s.strip.downcase
  end

  def parse_history
    return [] if params[:history].blank?

    history = JSON.parse(params[:history])
    valid_turns = history.is_a?(Array) && history.length <= 8 && history.all? do |turn|
      turn.is_a?(Hash) &&
        %w[user assistant].include?(turn["role"]) &&
        turn["content"].is_a?(String) &&
        turn["content"].length <= 2_000
    end

    total_bytes = history.sum { |turn| turn["content"].bytesize } if valid_turns
    return history if valid_turns && total_bytes <= 8_000

    @error = "This chat is too long to continue. Please start a new conversation."
    nil
  rescue JSON::ParserError
    @error = "Chat history could not be read. Please refresh the page and try again."
    nil
  end

  def ai_rate_limit_exceeded
    @language = "english"
    @error = "Too many AI requests. Please wait a few minutes and try again."
    respond_with_error(:too_many_requests)
  end

  def respond_with_error(status)
    respond_to do |format|
      format.html { render :index, status: status }
      format.json { render json: { error: @error }, status: status }
    end
  end
end
