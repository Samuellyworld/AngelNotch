import { styled } from "styled-components";

export const Backdrop = styled.div`
  position: fixed;
  inset: 0;
  z-index: 300;
  display: grid;
  place-items: center;
  padding: 1.2rem;
  background: rgba(4, 4, 3, 0.78);
  backdrop-filter: blur(18px);
  animation: gate-in 260ms ease both;

  @keyframes gate-in {
    from {
      opacity: 0;
    }
  }
`;

export const DialogCard = styled.div`
  position: relative;
  overflow: hidden;
  width: min(100%, 34rem);
  padding: clamp(1.5rem, 1.1rem + 2vw, 2.5rem);
  border: 1px solid var(--outline-strong);
  border-radius: clamp(22px, 4vw, 30px);
  background:
    radial-gradient(80% 90% at 50% 110%, rgba(232, 133, 97, 0.2), transparent 68%),
    var(--canvas-raised);
  box-shadow: 0 34px 100px rgba(0, 0, 0, 0.52);
  animation: card-in 520ms var(--ease-out) both;

  @keyframes card-in {
    from {
      opacity: 0;
      transform: translateY(22px) scale(0.97);
    }
  }
`;

export const CloseButton = styled.button`
  position: absolute;
  top: 1rem;
  right: 1rem;
  display: grid;
  width: 2.2rem;
  height: 2.2rem;
  place-items: center;
  border: 1px solid var(--outline);
  border-radius: 50%;
  background: var(--surface);
  color: var(--ink-secondary);
  font-size: 1.25rem;
  line-height: 1;
  transition:
    border-color var(--dur-fast) ease,
    color var(--dur-fast) ease,
    transform var(--dur-fast) ease;

  &:hover {
    border-color: var(--outline-strong);
    color: var(--ink-primary);
    transform: rotate(5deg);
  }
`;

export const Eyebrow = styled.p`
  margin-bottom: 1rem;
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
`;

export const GateTitle = styled.h2`
  max-width: 11ch;
  padding-right: 2.5rem;
  font-size: clamp(2rem, 1.45rem + 2.6vw, 3.35rem);
  letter-spacing: -0.05em;
`;

export const GateBody = styled.p`
  max-width: 42ch;
  margin-top: 1rem;
  color: var(--ink-secondary);
  line-height: 1.55;
`;

export const Form = styled.form`
  display: grid;
  gap: 0.9rem;
  margin-top: 1.65rem;
`;

export const Label = styled.label`
  color: var(--ink-secondary);
  font-size: 0.82rem;
`;

export const EmailInput = styled.input`
  width: 100%;
  padding: 0.92rem 1rem;
  border: 1px solid var(--outline-strong);
  border-radius: 14px;
  outline: none;
  background: rgba(243, 237, 227, 0.06);
  color: var(--ink-primary);
  font: inherit;
  transition:
    border-color var(--dur-fast) ease,
    box-shadow var(--dur-fast) ease;

  &::placeholder {
    color: var(--ink-faint);
  }

  &:focus {
    border-color: rgba(232, 133, 97, 0.72);
    box-shadow: 0 0 0 4px rgba(232, 133, 97, 0.11);
  }
`;

export const ConsentLabel = styled.label`
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: start;
  gap: 0.65rem;
  color: var(--ink-tertiary);
  font-size: 0.78rem;
  line-height: 1.5;

  input {
    width: 1rem;
    height: 1rem;
    margin-top: 0.15rem;
    accent-color: var(--accent);
  }

  a {
    border-bottom: 1px solid var(--outline-strong);
    color: var(--ink-secondary);
  }
`;

export const SubmitButton = styled.button`
  display: inline-flex;
  min-height: 3.15rem;
  align-items: center;
  justify-content: center;
  padding: 0.82rem 1.25rem;
  border-radius: var(--r-pill);
  background: var(--cream);
  color: #14100c;
  font-weight: 600;
  transition:
    background-color var(--dur) var(--ease-out),
    box-shadow var(--dur) var(--ease-out),
    transform var(--dur) var(--ease-out);

  &:hover:not(:disabled) {
    background: var(--accent);
    box-shadow: 0 16px 34px -18px rgba(232, 133, 97, 0.7);
    transform: translateY(-2px);
  }

  &:disabled {
    cursor: wait;
    opacity: 0.62;
  }
`;

export const FormNote = styled.p`
  color: var(--ink-faint);
  font-size: 0.74rem;
  line-height: 1.5;
  text-align: center;
`;

export const Honeypot = styled.div`
  position: absolute;
  left: -10000px;
  width: 1px;
  height: 1px;
  overflow: hidden;
`;
