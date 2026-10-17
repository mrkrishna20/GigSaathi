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
    with_method_stub(AssistantResponseGenerator, :call, ->(**) { "Take regular breaks and stay hydrated." }) do
      post ask_assistant_path, params: { question: "How can I stay safe?", language: "english" }
    end

    assert_response :success
    assert_select ".answer-copy", text: /Take regular breaks/
  end

  test "assistant clearly reports missing AI configuration" do
    with_method_stub(AssistantResponseGenerator, :call, ->(**) { raise LlmClient::ConfigurationError, "AI is not configured. Set LLM_API_KEY." }) do
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
    worker = create_worker
    sign_in_worker(worker)

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

    assert_equal worker.id, Earning.order(:id).last.user_id
    assert_redirected_to earnings_path
    follow_redirect!
    assert_select ".entry-heading strong", text: /₹1,025.00/
  end

  test "earnings form rejects negative expenses" do
    sign_in_worker(create_worker)

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
    with_method_stub(ComplaintGenerator, :call, ->(**) { "Hello, please review my delayed payment." }) do
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

  test "earnings are private and cannot be deleted by another account" do
    owner = create_worker
    earning = owner.earnings.create!(
      work_date: Date.current,
      total_earnings: 750,
      fuel_expenses: 50,
      food_expenses: 0,
      other_expenses: 0
    )

    sign_in_worker(create_worker)

    get earnings_path
    assert_response :success
    assert_select ".empty-state", text: /Your first entry starts here/

    delete earning_path(earning)
    assert_response :not_found
    assert Earning.exists?(earning.id)
  end

  test "earnings pages redirect workers who are not signed in" do
    get earnings_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :success
    assert_select "[role=alert]", text: /Please sign in/
  end

  test "earnings history is paginated without exposing another account's entries" do
    worker = create_worker
    21.times do |day|
      worker.earnings.create!(
        work_date: Date.current - day.days,
        total_earnings: day + 100,
        fuel_expenses: 0,
        food_expenses: 0,
        other_expenses: 0
      )
    end
    sign_in_worker(worker)

    get earnings_path
    assert_response :success
    assert_select ".earning-entry", count: 20
    assert_select "a[rel=next]", text: /Older entries/

    get earnings_path(page: 2)
    assert_response :success
    assert_select ".earning-entry", count: 1
    assert_select "a[rel=prev]", text: /Newer entries/
  end

  test "account creation signs the worker in" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        user: {
          email: "  Worker@Example.com ",
          password: "strong-example-password",
          password_confirmation: "strong-example-password"
        }
      }
    end

    assert_redirected_to earnings_path
    follow_redirect!
    assert_response :success
    assert_equal "worker@example.com", User.order(:id).last.email
    assert_select ".nav-account", text: "worker@example.com"
  end

  test "account creation rejects mismatched passwords" do
    assert_no_difference("User.count") do
      post users_path, params: {
        user: {
          email: "worker@example.com",
          password: "strong-example-password",
          password_confirmation: "a-different-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Password confirmation/
  end

  test "login errors do not reveal whether an email has an account" do
    post session_path, params: { email: "unknown@example.com", password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: "Email or password is incorrect."
  end

  test "a worker can sign out and loses access to private earnings" do
    worker = create_worker
    sign_in_worker(worker)

    delete destroy_session_path

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select ".nav-signup", text: "Create account"

    get earnings_path
    assert_redirected_to new_session_path
  end

  test "AI endpoints reject requests above the per-IP limit" do
    with_method_stub(AssistantResponseGenerator, :call, ->(**) { "A helpful response." }) do
      20.times do
        post ask_assistant_path, params: { question: "A short question?", language: "english" }
        assert_response :success
      end

      post ask_assistant_path, params: { question: "One more question?", language: "english" }
    end

    assert_response :too_many_requests
    assert_select "[role=alert]", text: /Too many AI requests/
  end

  private

  def create_worker
    User.create!(
      email: "worker-#{SecureRandom.hex(6)}@example.com",
      password: "strong-example-password",
      password_confirmation: "strong-example-password"
    )
  end

  def sign_in_worker(worker)
    post session_path, params: {
      email: worker.email,
      password: "strong-example-password"
    }
    assert_redirected_to earnings_path
    follow_redirect!
    assert_response :success
  end
end
