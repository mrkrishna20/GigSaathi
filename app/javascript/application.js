import "@hotwired/turbo-rails";

document.addEventListener("submit", async (event) => {
  const form = event.target.closest("[data-chat-form]");
  if (!form) return;

  event.preventDefault();

  const input = form.querySelector("[data-chat-input]");
  const submitButton = form.querySelector("[data-chat-submit]");
  const submitLabel = form.querySelector("[data-chat-submit-label]");
  const messages = document.querySelector("[data-chat-messages]");
  const status = document.querySelector("[data-chat-status]");
  const errorMessage = document.querySelector("[data-chat-error]");
  const question = input.value.trim();

  if (!question || form.dataset.submitting === "true") return;

  const history = [...messages.querySelectorAll(".chat-message")].map((message) => ({
    role: message.classList.contains("user-message") ? "user" : "assistant",
    content: message.querySelector(".chat-bubble p").textContent
  })).slice(-8);
  const payload = new FormData(form);
  payload.set("question", question);
  payload.set("history", JSON.stringify(history));

  form.dataset.submitting = "true";
  submitButton.disabled = true;
  submitLabel.textContent = "Sending…";
  status.textContent = "GigSaathi is preparing a reply…";
  errorMessage.hidden = true;
  errorMessage.textContent = "";
  appendChatMessage(messages, question, "You", "user");
  input.value = "";

  try {
    const response = await fetch(form.action, {
      method: form.method.toUpperCase(),
      body: payload,
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    });
    const result = await response.json().catch(() => ({}));

    if (!response.ok || typeof result.answer !== "string" || !result.answer.trim()) {
      throw new Error(result.error || "GigSaathi couldn't answer right now. Please try again.");
    }

    appendChatMessage(messages, result.answer, "GigSaathi", "assistant");
    status.textContent = "Reply received.";
  } catch (error) {
    errorMessage.textContent = error.message || "Unable to reach GigSaathi. Check your connection and try again.";
    errorMessage.hidden = false;
    status.textContent = "Your message could not be answered.";
    input.value = question;
  } finally {
    form.dataset.submitting = "false";
    submitButton.disabled = false;
    submitLabel.textContent = "Send";
    input.focus();
    messages.scrollTop = messages.scrollHeight;
  }
}, true);

document.addEventListener("keydown", (event) => {
  if (event.target.matches("[data-chat-input]") && event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    event.target.form.requestSubmit();
  }
});

function appendChatMessage(container, text, speaker, kind) {
  const article = document.createElement("article");
  article.className = `chat-message ${kind}-message`;

  const avatar = document.createElement("span");
  avatar.className = "chat-avatar";
  avatar.setAttribute("aria-hidden", "true");
  avatar.textContent = kind === "assistant" ? "g" : "•";

  const bubble = document.createElement("div");
  bubble.className = "chat-bubble";

  const label = document.createElement("strong");
  label.textContent = speaker;
  const content = document.createElement("p");
  content.textContent = text;

  bubble.append(label, content);
  article.append(avatar, bubble);
  container.append(article);
}

document.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-copy-target]");
  if (!button) return;

  const textArea = document.getElementById(button.dataset.copyTarget);
  const status = button.parentElement.querySelector(".copy-status");
  if (!textArea || !status) return;

  try {
    await navigator.clipboard.writeText(textArea.value);
    status.textContent = "Complaint copied to clipboard.";
  } catch (_error) {
    textArea.focus();
    textArea.select();
    status.textContent = "Clipboard access is unavailable. The draft is selected—copy it manually.";
  }
});
