import { styled } from "styled-components";

import { Reveal } from "@/components/ui";

export const ExtensionBand = styled.div`
  position: relative;
  padding-bottom: clamp(4rem, 8vw, 7rem);
  background: var(--canvas);
`;

export const ExtensionIcon = styled.span`
  display: grid;
  width: 3rem;
  height: 3rem;
  flex-shrink: 0;
  place-items: center;
  border: 1px solid var(--outline);
  border-radius: 15px;
  background: var(--surface);
  color: var(--cyan);
  transition:
    transform 700ms var(--ease-out),
    color 700ms var(--ease-out),
    box-shadow 700ms var(--ease-out);
`;

export const ExtensionCard = styled(Reveal)`
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: clamp(1.2rem, 0.6rem + 2vw, 2.4rem);
  padding: clamp(1.4rem, 1rem + 1.6vw, 2.2rem);
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background: var(--canvas-raised);
  transition:
    transform 700ms var(--ease-out),
    border-color 700ms var(--ease-out),
    box-shadow 700ms var(--ease-out);

  &:hover {
    border-color: var(--outline-strong);
    box-shadow: 0 26px 70px -48px rgba(133, 179, 179, 0.42);
    transform: translateY(-4px);
  }

  &:hover ${ExtensionIcon} {
    color: #a8d2d2;
    box-shadow: 0 12px 30px -18px rgba(133, 179, 179, 0.72);
    transform: rotate(8deg) scale(1.04);
  }

  @media (max-width: 900px) {
    grid-template-columns: auto minmax(0, 1fr);

    > :last-child {
      grid-column: 1 / -1;
    }
  }

  @media (max-width: 600px) {
    grid-template-columns: 1fr;
    gap: 1rem;
    padding: 1.2rem;

    > :last-child {
      grid-column: auto;
      justify-content: center;
      width: 100%;
    }
  }

  @media (hover: none) {
    &:hover {
      transform: none;
    }

    &:hover ${ExtensionIcon} {
      transform: none;
    }
  }
`;

export const ExtensionTitle = styled.h3`
  margin-bottom: 0.3rem;
  font-size: var(--step-1);
  letter-spacing: -0.03em;
`;

export const ExtensionBody = styled.p`
  max-width: 58ch;
  color: var(--ink-secondary);
  font-size: 0.93rem;
  line-height: 1.55;
`;

export const Optional = styled.span`
  margin-left: 0.55rem;
  padding: 0.15rem 0.5rem;
  border: 1px solid var(--outline);
  border-radius: var(--r-pill);
  color: var(--ink-tertiary);
  font-family: var(--font-mono);
  font-size: 0.58rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  vertical-align: middle;

  @media (max-width: 600px) {
    display: inline-block;
    margin-top: 0.4rem;
    margin-left: 0;
  }
`;
