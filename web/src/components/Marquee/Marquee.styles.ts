import { keyframes, styled } from "styled-components";

const slide = keyframes`
  to {
    transform: translateX(-100%);
  }
`;

const sweep = keyframes`
  0%,
  54% {
    transform: translateX(-110%);
  }

  100% {
    transform: translateX(520%);
  }
`;

const iconFloat = keyframes`
  50% {
    opacity: 1;
    transform: translateY(-1.5px);
  }
`;

export const MarqueeTrack = styled.div`
  position: relative;
  z-index: 1;
  display: flex;
  flex-shrink: 0;
  align-items: center;
  gap: 0.8rem;
  padding-right: 0.8rem;
  animation: ${slide} 46s linear infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
`;

export const MarqueeItem = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 0.62rem;
  padding: 0.46rem 0.78rem;
  border: 1px solid rgba(243, 237, 227, 0.075);
  border-radius: var(--r-pill);
  background: rgba(243, 237, 227, 0.025);
  color: rgba(243, 237, 227, 0.46);
  font-family: var(--font-mono);
  font-size: 0.67rem;
  letter-spacing: 0.13em;
  text-transform: uppercase;
  white-space: nowrap;
  transition:
    color var(--dur) var(--ease-out),
    border-color var(--dur) var(--ease-out),
    background-color var(--dur) var(--ease-out),
    transform var(--dur) var(--ease-out);

  &:hover {
    border-color: rgba(232, 133, 97, 0.28);
    background: rgba(232, 133, 97, 0.075);
    color: var(--cream);
    transform: translateY(-1px);
  }

  svg {
    color: var(--accent);
    opacity: 0.82;
    animation: ${iconFloat} 3.2s ease-in-out infinite;
  }

  &:nth-child(3n + 2) svg {
    color: var(--cyan);
    animation-delay: -1.1s;
  }

  &:nth-child(3n + 3) svg {
    color: var(--violet);
    animation-delay: -2.2s;
  }

  @media (prefers-reduced-motion: reduce) {
    svg {
      animation: none;
    }
  }
`;

export const MarqueeRoot = styled.div`
  position: relative;
  isolation: isolate;
  display: flex;
  overflow: hidden;
  padding-block: clamp(0.85rem, 0.65rem + 0.6vw, 1.15rem);
  border-block: 1px solid var(--outline);
  background:
    linear-gradient(
      90deg,
      rgba(232, 133, 97, 0.025),
      transparent 28% 72%,
      rgba(232, 133, 97, 0.025)
    ),
    #0b0b0a;
  mask-image: linear-gradient(90deg, transparent, #000 8%, #000 92%, transparent);
  user-select: none;

  &::before {
    position: absolute;
    inset: 0 auto 0 0;
    z-index: 0;
    width: 24%;
    background: linear-gradient(90deg, transparent, rgba(232, 133, 97, 0.08), transparent);
    content: "";
    pointer-events: none;
    transform: translateX(-110%);
    animation: ${sweep} 9s var(--ease-inout) infinite;
  }

  &:hover ${MarqueeTrack} {
    animation-play-state: paused;
  }

  @media (prefers-reduced-motion: reduce) {
    &::before {
      animation: none;
    }
  }
`;
