require "test_helper"

class LlmClientTest < ActiveSupport::TestCase
  ENVIRONMENT_LOCK = Mutex.new

  test "reports missing credentials instead of returning a fallback answer" do
    with_ai_environment("LLM_API_KEY" => nil, "OPENAI_API_KEY" => nil) do
      error = assert_raises(LlmClient::ConfigurationError) do
        LlmClient.new(messages: []).call
      end

      assert_match(/Set LLM_API_KEY/, error.message)
    end
  end

  test "rejects an invalid API URL as a configuration error" do
    with_ai_environment("LLM_API_KEY" => "test-key", "LLM_API_URL" => "not a URL") do
      error = assert_raises(LlmClient::ConfigurationError) do
        LlmClient.new(messages: []).call
      end

      assert_match(/LLM_API_URL must be a valid HTTP or HTTPS URL/, error.message)
    end
  end

  private

  def with_ai_environment(values)
    ENVIRONMENT_LOCK.synchronize do
      original_values = values.keys.to_h { |key| [ key, ENV[key] ] }
      values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      original_values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
