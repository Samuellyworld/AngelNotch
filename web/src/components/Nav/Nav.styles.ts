import { css, styled } from "styled-components";

import { Icon } from "@/components/icons";

export const NavWrap = styled.div`
  position: fixed;
  inset: 0 0 auto;
  z-index: 100;
  display: flex;
  justify-content: center;
  padding: clamp(0.7rem, 0.4rem + 0.9vw, 1.15rem) var(--gutter);
  pointer-events: none;

  @media (max-width: 520px) {
    padding: 0.65rem 0.7rem;
  }
`;

export const NavBar = styled.nav<{ $docked: boolean }>`
  display: flex;
  width: 100%;
  max-width: 1120px;
  align-items: center;
  gap: clamp(0.6rem, 0.2rem + 1.4vw, 1.6rem);
  padding: 0.5rem 0.55rem 0.5rem 1.05rem;
  border: 1px solid transparent;
  border-radius: var(--r-pill);
  background: transparent;
  pointer-events: auto;
  transition:
    background-color var(--dur) var(--ease-out),
    border-color var(--dur) var(--ease-out),
    box-shadow var(--dur) var(--ease-out),
    backdrop-filter var(--dur) var(--ease-out);

  ${({ $docked }) =>
    $docked &&
    css`
      border-color: var(--outline);
      background: rgba(10, 10, 9, 0.88);
      box-shadow: 0 18px 44px -26px rgba(0, 0, 0, 0.95);
      backdrop-filter: blur(26px) saturate(160%);
    `}

  @media (max-width: 520px) {
    padding: 0.42rem 0.45rem 0.42rem 0.75rem;

    ${({ $docked }) =>
      $docked &&
      css`
        backdrop-filter: blur(18px) saturate(145%);
      `}
  }
`;

export const Brand = styled.a`
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  font-size: 1.02rem;
  font-weight: 500;
  letter-spacing: -0.03em;

  @media (prefers-reduced-motion: reduce) {
    [data-logo-pulse] {
      display: none;
    }
  }

  @media (max-width: 520px) {
    gap: 0.42rem;
    font-size: 0.9rem;

    svg {
      width: 21px;
      height: 21px;
    }
  }
`;

export const Actions = styled.div`
  display: flex;
  align-items: center;
  gap: 0.45rem;
  margin-left: auto;
`;

export const StarIcon = styled(Icon)`
  color: var(--ink-tertiary);
  transition:
    color var(--dur) var(--ease-out),
    transform var(--dur) var(--ease-out);
`;

export const StarLink = styled.a`
  position: relative;
  isolation: isolate;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  overflow: hidden;
  padding: 0.5rem 0.8rem;
  border: 1px solid var(--outline);
  border-radius: var(--r-pill);
  background: var(--surface);
  color: var(--ink-secondary);
  font-size: 0.84rem;
  transition:
    color 320ms ease,
    border-color 420ms var(--ease-out),
    background-color 420ms var(--ease-out),
    transform 420ms var(--ease-out),
    box-shadow 420ms var(--ease-out);

  &::before {
    position: absolute;
    top: var(--hover-y, 50%);
    left: var(--hover-x, 50%);
    z-index: 0;
    width: 180%;
    aspect-ratio: 1;
    border-radius: 50%;
    background: var(--cream);
    content: "";
    transform: translate(-50%, -50%) scale(0);
    transition: transform 620ms var(--ease-out);
  }

  > * {
    position: relative;
    z-index: 1;
  }

  &:hover {
    border-color: var(--cream);
    box-shadow: 0 14px 30px -21px rgba(243, 237, 227, 0.65);
    color: #14100c;
    transform: translateY(-2px);
  }

  &:hover::before {
    transform: translate(-50%, -50%) scale(1);
  }

  &:hover ${StarIcon} {
    color: var(--accent-deep);
    transform: rotate(-18deg) scale(1.16);
  }

  @media (max-width: 520px) {
    padding: 0.48rem;
  }
`;

export const StarLabel = styled.span`
  @media (max-width: 520px) {
    display: none;
  }
`;

export const Progress = styled.span`
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 1px;
  background: linear-gradient(90deg, var(--accent-deep), var(--accent));
  opacity: 0.85;
  transform: scaleX(0);
  transform-origin: left;
`;
