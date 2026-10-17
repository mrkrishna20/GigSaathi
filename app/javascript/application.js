import "@hotwired/turbo-rails";

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
