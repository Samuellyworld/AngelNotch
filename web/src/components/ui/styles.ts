import { css, styled } from "styled-components";

export type ButtonVariant = "primary" | "secondary" | "ghost";

export const ButtonMeta = styled.span`
  color: rgba(20, 16, 12, 0.5);
  font-family: var(--font-mono);
  font-size: 0.7rem;
  letter-spacing: 0.04em;
  transition: color 320ms ease;
`;

const buttonVariants = {
  primary: css`
    background: var(--cream);
    color: #14100c;

    &::before {
      background: var(--accent);
    }

    &:hover {
      box-shadow:
        0 16px 34px -18px rgba(232, 133, 97, 0.7),
        inset 0 1px 0 rgba(255, 255, 255, 0.22);
      transform: translateY(-3px);
    }
  `,
  secondary: css`
    border: 1px solid var(--outline);
    background: var(--surface);
    color: var(--ink-primary);
    backdrop-filter: blur(14px);

    &::before {
      background: var(--cream);
    }

    &:hover {
      border-color: var(--cream);
      box-shadow: 0 16px 34px -22px rgba(243, 237, 227, 0.52);
      color: #14100c;
      transform: translateY(-3px);
    }

    &:hover ${ButtonMeta} {
      color: rgba(20, 16, 12, 0.52);
    }

    ${ButtonMeta} {
      color: var(--ink-tertiary);
    }
  `,
  ghost: css`
    padding-inline: 0.2rem;
    color: var(--ink-secondary);

    &:hover {
      color: var(--ink-primary);
      transform: translateX(3px);
    }

    ${ButtonMeta} {
      color: var(--ink-tertiary);
    }
  `,
} satisfies Record<ButtonVariant, ReturnType<typeof css>>;

export const ButtonAnchor = styled.a<{ $variant: ButtonVariant; $small: boolean }>`
  --pad-x: 1.35rem;

  position: relative;
  isolation: isolate;
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  overflow: hidden;
  padding: 0.82rem var(--pad-x);
  border-radius: var(--r-pill);
  font-size: var(--step-0);
  font-weight: 500;
  letter-spacing: -0.015em;
  white-space: nowrap;
  transition:
    transform 420ms var(--ease-out),
    background-color 420ms var(--ease-out),
    border-color 420ms var(--ease-out),
    color 320ms ease,
    box-shadow 420ms var(--ease-out);

  &::before {
    position: absolute;
    top: var(--hover-y, 50%);
    left: var(--hover-x, 50%);
    z-index: 0;
    width: 180%;
    aspect-ratio: 1;
    border-radius: 50%;
    content: "";
    transform: translate(-50%, -50%) scale(0);
    transition: transform 680ms var(--ease-out);
  }

  > * {
    position: relative;
    z-index: 1;
  }

  &:hover::before,
  &:focus-visible::before {
    transform: translate(-50%, -50%) scale(1);
  }

  svg {
    transition:
      color 320ms ease,
      transform 520ms var(--ease-out);
  }

  &:hover svg[data-slide] {
    transform: translateX(5px) rotate(-8deg);
  }

  &:hover > svg:first-child {
    transform: translateY(2px) scale(1.08);
  }

  &:active {
    transform: translateY(0) scale(0.965);
    transition-duration: 90ms;
  }

  ${({ $variant }) => buttonVariants[$variant]}

  ${({ $small }) =>
    $small &&
    css`
      --pad-x: 1rem;

      padding-block: 0.55rem;
      font-size: var(--step--1);
    `}
`;

export const RevealBlock = styled.div<{ $shown: boolean; $delay: number }>`
  opacity: ${({ $shown }) => ($shown ? 1 : 0)};
  transform: ${({ $shown }) => ($shown ? "none" : "translate3d(0, 24px, 0)")};
  transition:
    opacity 760ms var(--ease-out),
    transform 940ms var(--ease-out);
  transition-delay: ${({ $delay }) => `${$delay}ms`};
  will-change: opacity, transform;

  @media (prefers-reduced-motion: reduce) {
    opacity: 1;
    transform: none;
  }

  @media (max-width: 760px) {
    transform: ${({ $shown }) => ($shown ? "none" : "translate3d(0, 12px, 0)")};
    transition-duration: 480ms, 560ms;
  }
`;

export const SectionRoot = styled.section`
  position: relative;
  padding-block: var(--section-y);
`;

export const SectionHead = styled.header`
  display: flex;
  flex-direction: column;
  gap: 1.6rem;
  padding-bottom: clamp(2.5rem, 1.5rem + 3vw, 4.5rem);

  @media (max-width: 760px) {
    gap: 1.15rem;
    padding-bottom: 2.4rem;
  }
`;

export const SectionRail = styled.p`
  display: flex;
  align-items: center;
  gap: 0.85rem;
  color: var(--ink-tertiary);
  font-family: var(--font-mono);
  font-size: var(--step--1);
  letter-spacing: 0.06em;
  text-transform: uppercase;

  &::after {
    flex: 1;
    height: 1px;
    background: linear-gradient(90deg, var(--outline) 0%, transparent 92%);
    content: "";
  }
`;

export const SectionRailIndex = styled.span`
  color: var(--accent);
`;

export const SectionTitle = styled.h2`
  max-width: 20ch;
  font-size: var(--step-3);
`;

export const SectionLede = styled.p`
  max-width: 52ch;
  color: var(--ink-secondary);
  font-size: var(--step-1);
  line-height: 1.5;
  letter-spacing: -0.015em;
`;

export const KeysWrap = styled.span`
  display: inline-flex;
  gap: 0.3rem;
`;

export const Key = styled.kbd`
  display: grid;
  min-width: 2.15rem;
  height: 2.15rem;
  place-items: center;
  padding-inline: 0.55rem;
  border: 1px solid var(--outline-strong);
  border-bottom-width: 2px;
  border-radius: 9px;
  background: linear-gradient(180deg, rgba(243, 237, 227, 0.09), rgba(243, 237, 227, 0.03));
  box-shadow: inset 0 1px 0 rgba(243, 237, 227, 0.12);
  color: var(--ink-primary);
  font-family: var(--font-mono);
  font-size: 0.8rem;
  line-height: 1;

  @media (max-width: 760px) {
    min-width: 1.95rem;
    height: 1.95rem;
    padding-inline: 0.45rem;
    font-size: 0.74rem;
  }
`;

export const Frame = styled.figure`
  position: relative;
  overflow: hidden;
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background:
    radial-gradient(120% 90% at 50% -10%, rgba(232, 133, 97, 0.14), transparent 62%),
    var(--canvas-raised);

  &::after {
    position: absolute;
    inset: 0;
    border-radius: inherit;
    box-shadow: inset 0 1px 0 rgba(243, 237, 227, 0.08);
    content: "";
    pointer-events: none;
  }
`;

export const FrameImage = styled.img`
  width: 100%;
  height: auto;
`;

export const FrameTag = styled.figcaption`
  position: absolute;
  bottom: 0.9rem;
  left: 0.9rem;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.3rem 0.65rem;
  border: 1px solid var(--outline);
  border-radius: var(--r-pill);
  background: rgba(9, 9, 8, 0.62);
  color: var(--ink-tertiary);
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  backdrop-filter: blur(10px);
`;

export const FrameDot = styled.span`
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--mint);
  box-shadow: 0 0 0 3px rgba(148, 179, 158, 0.16);
`;
