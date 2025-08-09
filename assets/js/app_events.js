// Copy the content of the target element to the clipboard
//
// The field to be copied can be specified by the `field` attribute.
document.addEventListener("app:copy-to-clipboard", async function (event) {
  const { dispatcher, field = "value" } = event.detail;

  const copied = dispatcher[field];
  await navigator.clipboard.writeText(copied);
});
