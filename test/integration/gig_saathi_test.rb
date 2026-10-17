require "test_helper"

class GigSaathiTest < ActionDispatch::IntegrationTest
  test "home page links to all three features" do
    get root_path

    assert_response :success
    assert_select "a[href='#{assistant_path}']", text: /AI Assistant/
    assert_select "a[href='#{earnings_path}']", text: /My Earnings/
    assert_select "a[href='#{new_complaint_path}']", text: /Complaint Help/
  end

  test "assistant returns a generated answer in the selected language" do
    AssistantResponseGenerator.stub :call, "Take regular breaks and stay hydrated." do
      post ask_assistant_path, params: { question: "How can I stay safe?", language: "english" }
    end

    assert_response :success
    assert_select ".answer-copy", text: /Take regular breaks/
  end

  test "assistant clearly reports missing AI configuration" do
    AssistantResponseGenerator.stub :call, ->(**) { raise LlmClient::ConfigurationError, "AI is not configured. Set LLM_API_KEY." } do
      post ask_assistant_path, params: { question: "Is a scheme available?", language: "hindi" }
    end

    assert_response :service_unavailable
    assert_select "[role=alert]", text: /AI is not configured/
  end

  test "assistant rejects unsupported languages" do
    post ask_assistant_path, params: { question: "A question", language: "gibberish" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /supported language/
  end

  test "earnings entry is stored and net earnings are shown" do
    assert_difference("Earning.count", 1) do
      post earnings_path, params: {
        earning: {
          work_date: "2026-10-17",
          total_earnings: "1200.00",
          fuel_expenses: "100.00",
          food_expenses: "50.00",
          other_expenses: "25.00"
        }
      }
    end

    assert_redirected_to earnings_path
    follow_redirect!
    assert_select ".entry-heading strong", text: /₹1,025.00/
  end

  test "earnings form rejects negative expenses" do
    assert_no_difference("Earning.count") do
      post earnings_path, params: {
        earning: {
          work_date: "2026-10-17",
          total_earnings: "100",
          fuel_expenses: "-1",
          food_expenses: "0",
          other_expenses: "0"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Fuel expenses/
  end

  test "complaint generator returns an editable draft" do
    ComplaintGenerator.stub :call, "Hello, please review my delayed payment." do
      post generate_complaint_path, params: {
        category: "delayed_payment",
        company_name: "Example Delivery",
        description: "My payment for the last shift has not arrived.",
        language: "english"
      }
    end

    assert_response :success
    assert_select "textarea#complaint-draft", text: /please review my delayed payment/
    assert_select "button[data-copy-target='complaint-draft']", text: "Copy complaint"
  end

  test "complaint form rejects unknown categories" do
    post generate_complaint_path, params: {
      category: "invented",
      company_name: "",
      description: "I need help.",
      language: "english"
    }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Choose a category/
  end
end
