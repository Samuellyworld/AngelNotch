import { styled } from "styled-components";

import { Reveal, Section } from "@/components/ui";

export const IntroSection = styled(Section)`
  --ink-primary: #171613;
  --ink-secondary: rgba(23, 22, 19, 0.64);
  --ink-tertiary: rgba(23, 22, 19, 0.44);
  --ink-faint: rgba(23, 22, 19, 0.28);
  --outline: rgba(23, 22, 19, 0.13);
  --outline-strong: rgba(23, 22, 19, 0.22);
  --canvas: #f1eee8;
  --canvas-raised: #e7e2da;
  --surface: rgba(23, 22, 19, 0.06);
  --surface-quiet: rgba(23, 22, 19, 0.035);
  --surface-raised: rgba(23, 22, 19, 0.09);

  z-index: 2;
  min-height: 100vh;
  padding-top: clamp(4.5rem, 8vh, 7rem);
  background: #f1eee8;
  color: #171613;

  @media (max-width: 600px) {
    min-height: 0;
    padding-top: 4.5rem;
  }
`;

export const IntroGrid = styled.div`
  display: grid;
  grid-template-columns: minmax(0, 1.05fr) minmax(0, 1fr);
  align-items: end;
  gap: clamp(2rem, 1rem + 4vw, 5rem);

  @media (max-width: 900px) {
    grid-template-columns: 1fr;
    align-items: start;
  }

  @media (max-width: 600px) {
    gap: 2rem;
  }
`;

export const IntroHeadline = styled.h2`
  font-size: var(--step-4);
  line-height: 0.9;
  letter-spacing: -0.05em;
`;

export const IntroBody = styled(Reveal)`
  display: flex;
  max-width: 46ch;
  flex-direction: column;
  gap: 1.4rem;
  color: var(--ink-secondary);
  font-size: var(--step-1);
  line-height: 1.5;
  letter-spacing: -0.015em;

  @media (max-width: 600px) {
    gap: 1rem;
    font-size: 1rem;
  }
`;

export const Pillars = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: clamp(1.5rem, 1rem + 2vw, 3rem);
  margin-top: clamp(3rem, 2rem + 4vw, 5.5rem);
  padding-top: clamp(2rem, 1.4rem + 2vw, 3rem);
  border-top: 1px solid var(--outline);

  @media (max-width: 600px) {
    grid-template-columns: 1fr;
    gap: 1.6rem;
    margin-top: 3rem;
    padding-top: 2rem;
  }
`;

export const Pillar = styled(Reveal)`
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
`;

export const PillarIndex = styled.span`
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.66rem;
  letter-spacing: 0.14em;
`;

export const PillarTitle = styled.h3`
  font-size: var(--step-1);
  letter-spacing: -0.03em;
`;

export const PillarBody = styled.p`
  color: var(--ink-secondary);
  font-size: 0.93rem;
  line-height: 1.6;
`;
