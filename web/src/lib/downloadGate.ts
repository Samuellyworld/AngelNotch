export const DOWNLOAD_GATE_EVENT = "angelnotch:open-download";

export const BREVO_SIGNUP_URL =
  "https://7acd61e3.sibforms.com/serve/MUIFAJ6Ws4klcQp64nSwaGKH9LFqjmrxVEFZLG6v9fZ0LyWcntJrFWWN0CF2nRqj8VP0KZ6guNQVSxMtBOoDmti4nEDks5Xe_GvfqD2__saig8nzXpYhE78dwnQ9U9K7FPVzhou2OObUjneiEgvhdHCHxr2Xg6Uay2JUwLD5MmHpK9kFEu1b6CXi5a7UcwPQJ1BQDBVCT4a9nioFtg==";

export function openDownloadGate(event?: { preventDefault: () => void }) {
  event?.preventDefault();
  window.dispatchEvent(new CustomEvent(DOWNLOAD_GATE_EVENT));
}
