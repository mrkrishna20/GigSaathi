require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"

class LlmClient
  class ConfigurationError < StandardError; end
  class RequestError < StandardError; end

  DEFAULT_URL = "https://api.openai.com/v1/chat/completions"
  DEFAULT_MODEL = "gpt-4o-mini"

  def initialize(messages:)
    @messages = messages
  end

  def call
    api_key = ENV["LLM_API_KEY"].presence || ENV["OPENAI_API_KEY"].presence
    raise ConfigurationError, "AI is not configured. Set LLM_API_KEY (or OPENAI_API_KEY) to enable this feature." if api_key.blank?

    begin
      uri = URI.parse(ENV["LLM_API_URL"].presence || DEFAULT_URL)
    rescue URI::InvalidURIError
      raise ConfigurationError, "LLM_API_URL must be a valid HTTP or HTTPS URL."
    end

    unless %w[http https].include?(uri.scheme) && uri.host.present?
      raise ConfigurationError, "LLM_API_URL must be a valid HTTP or HTTPS URL."
    end

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: ENV.fetch("LLM_MODEL", DEFAULT_MODEL),
      messages: @messages,
      temperature: 0.3
    }.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end

    raise RequestError, "LLM API returned HTTP #{response.code}." unless response.is_a?(Net::HTTPSuccess)

    content = JSON.parse(response.body).dig("choices", 0, "message", "content")
    raise RequestError, "LLM API returned an empty or invalid response." unless content.is_a?(String) && content.present?

    content
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPError, Net::ProtocolError, EOFError => error
    raise RequestError, "LLM API could not be reached (#{error.class})."
  rescue JSON::ParserError, TypeError, NoMethodError => error
    raise RequestError, "LLM API returned an invalid response (#{error.class})."
  end
end
