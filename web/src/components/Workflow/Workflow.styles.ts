import { keyframes, styled } from "styled-components";

import { Icon } from "@/components/icons";
import { Section } from "@/components/ui";

const notchBreathe = keyframes`
  50% {
    border-color: rgba(232, 133, 97, 0.24);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.07),
      0 22px 54px -24px rgba(232, 133, 97, 0.2);
  }
`;

export const WorkflowSection = styled(Section)`
  padding-top: calc(var(--section-y) + clamp(3.5rem, 8vh, 6rem));
  background: linear-gradient(
    180deg,
    #f1eee8 0,
    #f1eee8 1.5rem,
    rgba(42, 40, 36, 0.94) 6.5rem,
    var(--canvas) 11rem
  );

  @media (max-width: 600px) {
    padding-top: calc(var(--section-y) + 3rem);
  }
`;

export const WorkflowGrid = styled.div`
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 0.95fr);
  align-items: center;
  gap: clamp(2rem, 1rem + 4vw, 5rem);

  @media (max-width: 900px) {
    grid-template-columns: 1fr;
  }

  @media (max-width: 600px) {
    gap: 1.5rem;
  }
`;

export const Shortcuts = styled.div`
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background: var(--canvas-raised);
`;

export const Shortcut = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1.4rem;
  padding: 1.05rem clamp(1rem, 0.7rem + 1vw, 1.5rem);
  transition:
    background-color var(--dur) var(--ease-out),
    padding-left var(--dur) var(--ease-out);

  & + & {
    border-top: 1px solid var(--outline);
  }

  &:hover {
    padding-left: calc(clamp(1rem, 0.7rem + 1vw, 1.5rem) + 0.25rem);
    background: var(--surface-quiet);
  }

  @media (max-width: 600px) {
    gap: 0.8rem;
    padding: 0.9rem;

    &:hover {
      padding-left: 0.9rem;
    }
  }

  @media (hover: none) {
    &:hover {
      transform: none;
    }
  }
`;

export const ShortcutLabel = styled.span`
  color: var(--ink-secondary);
  font-size: 0.95rem;

  @media (max-width: 600px) {
    font-size: 0.84rem;
  }
`;

export const NotchChevron = styled(Icon)`
  color: var(--ink-tertiary);
  transition: transform var(--dur) var(--ease-out);
`;

export const NotchStrip = styled.div`
  margin-top: 1.4rem;
  padding: 1.1rem;
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background:
    radial-gradient(120% 140% at 50% 0%, rgba(232, 133, 97, 0.12), transparent 65%),
    var(--canvas-raised);

  &:hover ${NotchChevron} {
    transform: translateY(2px);
  }

  @media (max-width: 600px) {
    margin-top: 0;
    padding: 0.75rem;
  }
`;

export const NotchPreview = styled.div`
  position: relative;
  display: grid;
  min-height: 176px;
  place-items: start center;
  overflow: hidden;
  padding: 2.2rem 1rem;
  border-radius: 16px;
  background:
    radial-gradient(60% 110% at 50% -12%, rgba(232, 133, 97, 0.12), transparent 62%),
    linear-gradient(180deg, #10100f, #080807);

  @media (max-width: 600px) {
    min-height: 148px;
    padding-inline: 0.7rem;
  }
`;

export const NotchCamera = styled.span`
  position: absolute;
  top: 0;
  width: 8.5rem;
  height: 1.55rem;
  border-radius: 0 0 1rem 1rem;
  background: #000;
`;

export const NotchPill = styled.span`
  display: flex;
  width: min(100%, 390px);
  align-items: center;
  justify-content: space-between;
  margin-top: 1.6rem;
  padding: 0.72rem 1rem;
  border: 1px solid rgba(243, 237, 227, 0.1);
  border-radius: var(--r-pill);
  background:
    linear-gradient(110deg, rgba(232, 133, 97, 0.08), transparent 42%),
    #151513;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.055),
    0 18px 42px -25px rgba(0, 0, 0, 1);
  animation: ${notchBreathe} 4.8s var(--ease-inout) infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
`;

export const NotchCaption = styled.p`
  margin-top: 0.8rem;
  color: var(--ink-tertiary);
  font-size: 0.82rem;
  text-align: center;
`;
