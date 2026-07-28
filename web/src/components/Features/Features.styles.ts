import { css, keyframes, styled } from "styled-components";

import { Reveal } from "@/components/ui";

const iconBreathe = keyframes`
  0%,
  100% {
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.06),
      0 12px 28px -20px color-mix(in srgb, var(--tint) 58%, transparent);
  }

  50% {
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.1),
      0 15px 34px -16px color-mix(in srgb, var(--tint) 86%, transparent);
  }
`;

export const Rows = styled.div`
  display: flex;
  flex-direction: column;
  gap: clamp(4rem, 2rem + 7vw, 9rem);

  @media (max-width: 860px) {
    gap: 4.5rem;
  }
`;

export const Copy = styled(Reveal)`
  display: flex;
  max-width: 40ch;
  flex-direction: column;
  gap: 1.1rem;

  @media (max-width: 860px) {
    max-width: none;
  }

  @media (max-width: 560px) {
    gap: 0.8rem;
  }
`;

export const Meta = styled.p`
  display: flex;
  align-items: center;
  gap: 0.7rem;
  color: var(--ink-tertiary);
`;

export const Glyph = styled.span`
  display: grid;
  width: 2.5rem;
  height: 2.5rem;
  place-items: center;
  border: 1px solid var(--outline);
  border-radius: 13px;
  background: var(--surface);
  box-shadow: inset 0 1px 0 rgba(243, 237, 227, 0.06);
  color: var(--tint, var(--accent));
  transition:
    transform var(--dur) var(--ease-out),
    border-color var(--dur) var(--ease-out),
    box-shadow var(--dur) var(--ease-out);
`;

export const FeatureIndex = styled.span`
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 0.14em;
`;

export const FeatureTitle = styled.h3`
  font-size: var(--step-2);
  letter-spacing: -0.04em;
`;

export const FeatureBlurb = styled.p`
  color: var(--ink-secondary);
  line-height: 1.6;
`;

export const Media = styled(Reveal)`
  position: relative;
`;

export const VisualFrame = styled.figure<{ $plate: boolean }>`
  ${({ $plate }) =>
    $plate &&
    css`
      padding: clamp(1rem, 0.4rem + 2vw, 2.2rem);
      border: 1px solid var(--outline);
      border-radius: var(--r-card);
      background:
        radial-gradient(120% 100% at 50% 0%, rgba(232, 133, 97, 0.1), transparent 60%),
        linear-gradient(180deg, rgba(243, 237, 227, 0.045), rgba(243, 237, 227, 0.012));

      @media (max-width: 560px) {
        padding: 0.65rem;
      }
    `}
`;

export const Shot = styled.img<{ $capture: boolean }>`
  width: 100%;
  height: auto;
  border: ${({ $capture }) => ($capture ? "1px solid var(--outline)" : "0")};
  border-radius: 14px;
  box-shadow: 0 30px 70px -40px rgba(0, 0, 0, 0.95);
  transition:
    transform 800ms var(--ease-out),
    box-shadow 800ms var(--ease-out),
    filter 800ms var(--ease-out);

  @media (max-width: 560px) {
    border-radius: 12px;
  }
`;

export const FeatureRowContainer = styled.article<{ $tint: string }>`
  --tint: ${({ $tint }) => `var(${$tint})`};

  display: grid;
  grid-template-columns: 1fr 1fr;
  align-items: center;
  gap: clamp(1.8rem, 0.8rem + 4vw, 5rem);

  &:nth-child(even) ${Media} {
    order: -1;
  }

  &:hover ${Glyph} {
    border-color: color-mix(in srgb, var(--tint, var(--accent)) 42%, transparent);
    box-shadow:
      inset 0 1px 0 rgba(243, 237, 227, 0.08),
      0 10px 30px color-mix(in srgb, var(--tint, var(--accent)) 16%, transparent);
    transform: translateY(-3px) rotate(-2deg);
  }

  &:hover ${Shot} {
    box-shadow: 0 42px 90px -42px rgba(0, 0, 0, 1);
    filter: saturate(1.05) contrast(1.025);
    transform: translateY(-6px) scale(1.012);
  }

  @media (max-width: 860px) {
    grid-template-columns: 1fr;
    gap: 1.8rem;

    &:nth-child(even) ${Media} {
      order: 0;
    }
  }

  @media (hover: none) {
    &:hover ${Glyph},
    &:hover ${Shot} {
      transform: none;
    }

    &:hover ${Shot} {
      filter: none;
    }
  }
`;

export const MarkCards = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
  gap: 1px;
  overflow: hidden;
  margin-top: clamp(3.5rem, 2rem + 5vw, 6rem);
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background: var(--outline);

  @media (max-width: 560px) {
    grid-template-columns: 1fr;
    margin-top: 3.5rem;
  }
`;

export const MarkIcon = styled.span`
  display: grid;
  width: 2.8rem;
  height: 2.8rem;
  place-items: center;
  border: 1px solid color-mix(in srgb, var(--tint) 30%, var(--outline));
  border-radius: 14px;
  background: color-mix(in srgb, var(--tint) 9%, var(--surface));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.06),
    0 12px 28px -20px color-mix(in srgb, var(--tint) 70%, transparent);
  color: var(--tint, var(--accent));
  animation: ${iconBreathe} 4.8s var(--ease-inout) infinite;
  animation-delay: var(--motion-delay, 0ms);
  transition:
    transform var(--dur) var(--ease-out),
    border-color var(--dur) var(--ease-out);

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
`;

export const MarkCard = styled(Reveal)<{ $tint: string; $motionDelay: number }>`
  --tint: ${({ $tint }) => `var(${$tint})`};
  --motion-delay: ${({ $motionDelay }) => `${$motionDelay}ms`};

  position: relative;
  isolation: isolate;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  overflow: hidden;
  padding: clamp(1.4rem, 1rem + 1.2vw, 2rem);
  background: var(--canvas);
  transition:
    background-color var(--dur) var(--ease-out),
    transform var(--dur) var(--ease-out);

  &::after {
    position: absolute;
    top: -3rem;
    left: -2rem;
    z-index: -1;
    width: 9rem;
    height: 9rem;
    border-radius: 50%;
    background: radial-gradient(
      circle,
      color-mix(in srgb, var(--tint) 15%, transparent),
      transparent 68%
    );
    content: "";
    opacity: 0.55;
    transform: scale(0.82);
    transition:
      opacity 600ms var(--ease-out),
      transform 700ms var(--ease-out);
  }

  &:hover {
    background: var(--canvas-raised);
    transform: translateY(-3px);
  }

  &:hover::after {
    opacity: 1;
    transform: scale(1.2);
  }

  &:hover ${MarkIcon} {
    border-color: color-mix(in srgb, var(--tint) 54%, var(--outline));
    transform: translateY(-3px) rotate(-3deg) scale(1.04);
  }

  @media (hover: none) {
    &:hover,
    &:hover ${MarkIcon} {
      transform: none;
    }
  }
`;

export const MarkTitle = styled.h3`
  font-size: var(--step-1);
  letter-spacing: -0.03em;
`;

export const MarkBlurb = styled.p`
  color: var(--ink-secondary);
  font-size: 0.92rem;
  line-height: 1.55;
`;
