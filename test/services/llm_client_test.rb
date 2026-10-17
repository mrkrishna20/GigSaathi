require "test_helper"

class LlmClientTest < ActiveSupport::TestCase
  ENVIRONMENT_LOCK = Mutex.new

  test "reports missing credentials instead of returning a fallback answer" do
    with_ai_environment("GROQ_API_KEY" => nil, "LLM_API_KEY" => nil, "OPENAI_API_KEY" => nil) do
      error = assert_raises(LlmClient::ConfigurationError) do
        LlmClient.new(messages: []).call
      end

      assert_match(/Set GROQ_API_KEY or LLM_API_KEY/, error.message)
    end
  end

  test "rejects an invalid API URL as a configuration error" do
    with_ai_environment("LLM_API_KEY" => "test-key", "LLM_API_URL" => "not a URL") do
      error = assert_raises(LlmClient::ConfigurationError) do
        LlmClient.new(messages: []).call
      end

      assert_match(/HTTPS URL/, error.message)
    end
  end

  test "sends the configured API key over TLS as a bearer token" do
    sent_request = nil
    response_body = { choices: [ { message: { content: "Hello" } } ] }.to_json
    http = Object.new
    http.define_singleton_method(:request) do |request, &block|
      sent_request = request
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, response_body)
      response.define_singleton_method(:read_body) { |&reader| reader.call(@body) }
      block.call(response)
      response
    end

    with_ai_environment("GROQ_API_KEY" => nil, "LLM_API_KEY" => "test-key", "LLM_API_URL" => "https://example.test/chat") do
      with_method_stub(Net::HTTP, :start, ->(_host, _port, **_options, &block) { block.call(http) }) do
        assert_equal "Hello", LlmClient.new(messages: []).call
      end
    end

    assert_equal "Bearer test-key", sent_request["Authorization"]
    assert_equal URI::HTTPS, URI.parse(sent_request.uri.to_s).class
  end

  test "uses the Groq key, endpoint, and production model by default" do
    sent_request = nil
    sent_payload = nil
    response_body = { choices: [ { message: { content: "Groq response" } } ] }.to_json
    http = Object.new
    http.define_singleton_method(:request) do |request, &block|
      sent_request = request
      sent_payload = JSON.parse(request.body)
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, response_body)
      response.define_singleton_method(:read_body) { |&reader| reader.call(@body) }
      block.call(response)
      response
    end

    with_ai_environment(
      "GROQ_API_KEY" => "groq-test-key",
      "LLM_API_KEY" => nil,
      "OPENAI_API_KEY" => nil,
      "LLM_API_URL" => nil,
      "LLM_MODEL" => nil
    ) do
      with_method_stub(Net::HTTP, :start, ->(_host, _port, **_options, &block) { block.call(http) }) do
        assert_equal "Groq response", LlmClient.new(messages: []).call
      end
    end

    assert_equal "Bearer groq-test-key", sent_request["Authorization"]
    assert_equal URI.parse("https://api.groq.com/openai/v1/chat/completions"), sent_request.uri
    assert_equal "openai/gpt-oss-120b", sent_payload.fetch("model")
  end

  test "preserves OpenAI defaults for an OpenAI-specific key" do
    request_uri = nil
    response_body = { choices: [ { message: { content: "OpenAI response" } } ] }.to_json
    http = Object.new
    http.define_singleton_method(:request) do |request, &block|
      request_uri = request.uri
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, response_body)
      response.define_singleton_method(:read_body) { |&reader| reader.call(@body) }
      block.call(response)
      response
    end

    with_ai_environment(
      "GROQ_API_KEY" => nil,
      "LLM_API_KEY" => nil,
      "OPENAI_API_KEY" => "openai-test-key",
      "LLM_API_URL" => nil,
      "LLM_MODEL" => nil
    ) do
      with_method_stub(Net::HTTP, :start, ->(_host, _port, **_options, &block) { block.call(http) }) do
        assert_equal "OpenAI response", LlmClient.new(messages: []).call
      end
    end

    assert_equal URI.parse("https://api.openai.com/v1/chat/completions"), request_uri
  end

  test "rejects unencrypted API endpoints" do
    with_ai_environment("LLM_API_KEY" => "test-key", "LLM_API_URL" => "http://example.test/chat") do
      error = assert_raises(LlmClient::ConfigurationError) do
        LlmClient.new(messages: []).call
      end

      assert_match(/HTTPS URL/, error.message)
    end
  end

  test "rejects oversized model responses" do
    response_body = { choices: [ { message: { content: "x" * 32_001 } } ] }.to_json
    http = Object.new
    http.define_singleton_method(:request) do |_request, &block|
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@body, response_body)
      response.define_singleton_method(:read_body) { |&reader| reader.call(@body) }
      block.call(response)
      response
    end

    with_ai_environment("LLM_API_KEY" => "test-key", "LLM_API_URL" => "https://example.test/chat") do
      with_method_stub(Net::HTTP, :start, ->(_host, _port, **_options, &block) { block.call(http) }) do
        error = assert_raises(LlmClient::RequestError) do
          LlmClient.new(messages: []).call
        end

        assert_match(/32 KB size limit/, error.message)
      end
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
