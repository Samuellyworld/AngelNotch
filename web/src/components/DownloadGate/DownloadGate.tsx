import { useEffect, useId, useRef, useState } from "react";

import { BREVO_SIGNUP_URL, DOWNLOAD_GATE_EVENT } from "@/lib/downloadGate";
import {
  Backdrop,
  CloseButton,
  ConsentLabel,
  DialogCard,
  EmailInput,
  Eyebrow,
  Form,
  FormNote,
  GateBody,
  GateTitle,
  Honeypot,
  Label,
  SubmitButton,
} from "./DownloadGate.styles";

export function DownloadGate() {
  const [open, setOpen] = useState(false);
  const [consent, setConsent] = useState(false);
  const emailId = useId();
  const consentId = useId();
  const emailRef = useRef<HTMLInputElement>(null);

  const close = () => {
    setOpen(false);
  };

  useEffect(() => {
    const show = () => {
      setOpen(true);
      window.setTimeout(() => emailRef.current?.focus(), 40);
    };

    window.addEventListener(DOWNLOAD_GATE_EVENT, show);
    return () => window.removeEventListener(DOWNLOAD_GATE_EVENT, show);
  }, []);

  useEffect(() => {
    if (!open) return;

    const previousOverflow = document.body.style.overflow;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") close();
    };

    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  if (!open) return null;

  return (
    <Backdrop onMouseDown={(event) => event.target === event.currentTarget && close()}>
      <DialogCard role="dialog" aria-modal="true" aria-labelledby="download-gate-title">
        <CloseButton type="button" aria-label="Close download form" onClick={close}>
          ×
        </CloseButton>

        <Eyebrow>Free download · Product updates</Eyebrow>
        <GateTitle id="download-gate-title">Get AngelNotch.</GateTitle>
        <GateBody>
          Enter your email to download the macOS app and receive occasional release notes and
          product updates.
        </GateBody>

          <Form action={BREVO_SIGNUP_URL} method="POST">
            <Label htmlFor={emailId}>Email address</Label>
            <EmailInput
              ref={emailRef}
              id={emailId}
              type="email"
              name="EMAIL"
              placeholder="you@example.com"
              autoComplete="email"
              required
            />

            <Honeypot aria-hidden="true">
              <label htmlFor="download-email-check">Leave this field empty</label>
              <input
                id="download-email-check"
                name="email_address_check"
                tabIndex={-1}
                autoComplete="off"
              />
            </Honeypot>

            <input type="hidden" name="locale" value="en" />
            <input type="hidden" name="html_type" value="simple" />

            <ConsentLabel htmlFor={consentId}>
              <input
                id={consentId}
                type="checkbox"
                checked={consent}
                onChange={(event) => setConsent(event.target.checked)}
                required
              />
              <span>
                I agree to receive AngelNotch download and product emails. See the{" "}
                <a href="#privacy" onClick={close}>
                  privacy promise
                </a>
                .
              </span>
            </ConsentLabel>

            <SubmitButton type="submit" disabled={!consent}>
              Subscribe & download
            </SubmitButton>
            <FormNote>Brevo securely subscribes you, then starts the free download.</FormNote>
          </Form>
      </DialogCard>
    </Backdrop>
  );
}
