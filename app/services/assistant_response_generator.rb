class AssistantResponseGenerator
  def self.call(question:, language:)
    new(question:, language:).call
  end

  def initialize(question:, language:)
    @question = question
    @language = language
  end

  def call
    LlmClient.new(messages: [
      {
        role: "system",
        content: <<~PROMPT
          You are GigSaathi, a practical and respectful assistant for gig and daily-wage workers.
          Answer in #{@language}, using simple language and short, clear steps. Help with worker rights,
          safety, and public welfare schemes. Never invent a law, entitlement, scheme, eligibility rule,
          amount, deadline, contact, or source. If a fact depends on location or current rules, say what
          is uncertain, ask for the state/country if needed, and recommend checking an official government
          source. Do not present legal advice as a guarantee. For urgent danger, advise contacting local
          emergency services. Be transparent when you do not know.
        PROMPT
      },
      { role: "user", content: @question }
    ]).call
  end
end
