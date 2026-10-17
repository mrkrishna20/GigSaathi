require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"

class LlmClient
  class ConfigurationError < StandardError; end
  class RequestError < StandardError; end
  class ConnectionError < RequestError; end

  GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
  GROQ_MODEL = "openai/gpt-oss-120b"
  OPENAI_URL = "https://api.openai.com/v1/chat/completions"
  OPENAI_MODEL = "gpt-4o-mini"
  MAX_RESPONSE_BYTES = 32_000

  def initialize(messages:)
    @messages = messages
  end

  def call
    api_key = ENV["GROQ_API_KEY"].presence || ENV["LLM_API_KEY"].presence || ENV["OPENAI_API_KEY"].presence
    if api_key.blank?
      raise ConfigurationError, "AI is not configured. Set GROQ_API_KEY or LLM_API_KEY to enable this feature."
    end

    uri = api_uri
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"
    request.body = {
      model: ENV["LLM_MODEL"].presence || default_model,
      messages: @messages,
      temperature: 0.3
    }.to_json

    response_body = +""
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      http.request(request) do |http_response|
        if http_response.is_a?(Net::HTTPSuccess)
          http_response.read_body do |chunk|
            if response_body.bytesize + chunk.bytesize > MAX_RESPONSE_BYTES
              raise RequestError, "LLM API response exceeded the 32 KB size limit."
            end

            response_body << chunk
          end
        end
      end
    end

    raise RequestError, "LLM API returned HTTP #{response.code}." unless response.is_a?(Net::HTTPSuccess)

    content = JSON.parse(response_body).dig("choices", 0, "message", "content")
    raise RequestError, "LLM API returned an empty or invalid response." unless content.is_a?(String) && content.present?

    content
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPError, Net::ProtocolError, EOFError => error
    raise ConnectionError, "LLM API could not be reached (#{error.class})."
  rescue JSON::ParserError, TypeError, NoMethodError => error
    raise RequestError, "LLM API returned an invalid response (#{error.class})."
  end

  private

  def api_uri
    uri = URI.parse(ENV["LLM_API_URL"].presence || default_url)
    return uri if uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?

    raise ConfigurationError, "LLM_API_URL must be an HTTPS URL without embedded credentials."
  rescue URI::InvalidURIError
    raise ConfigurationError, "LLM_API_URL must be an HTTPS URL without embedded credentials."
  end

  def default_url
    return OPENAI_URL if ENV["OPENAI_API_KEY"].present? && ENV["GROQ_API_KEY"].blank? && ENV["LLM_API_KEY"].blank?

    GROQ_URL
  end

  def default_model
    default_url == OPENAI_URL ? OPENAI_MODEL : GROQ_MODEL
  end
end
