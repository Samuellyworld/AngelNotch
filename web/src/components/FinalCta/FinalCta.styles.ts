import { styled } from "styled-components";

import { Reveal } from "@/components/ui";

export const FinalBand = styled.div`
  padding-top: clamp(5rem, 10vh, 8rem);
  padding-bottom: var(--section-y);
  background: var(--canvas);
`;

export const CtaCard = styled(Reveal)`
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  overflow: hidden;
  padding: clamp(3.5rem, 2rem + 6vw, 7rem) clamp(1.5rem, 1rem + 3vw, 4rem);
  border: 1px solid var(--outline);
  border-radius: clamp(24px, 1rem + 2vw, 36px);
  background:
    radial-gradient(70% 120% at 50% 118%, rgba(232, 133, 97, 0.22), transparent 66%),
    var(--canvas-raised);
  text-align: center;

  @media (max-width: 600px) {
    padding: 3.25rem 1.2rem;
  }
`;

export const CtaTitle = styled.h2`
  max-width: 14ch;
  font-size: var(--step-4);
  letter-spacing: -0.05em;
`;

export const CtaBody = styled.p`
  max-width: 46ch;
  color: var(--ink-secondary);
  font-size: var(--step-1);
  line-height: 1.5;
  text-wrap: balance;
`;

export const CtaButtons = styled.div`
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0.65rem;
  margin-top: 0.4rem;

  @media (max-width: 600px) {
    width: 100%;
    flex-direction: column;

    > * {
      justify-content: center;
      width: 100%;
    }
  }
`;

export const CtaFine = styled.p`
  color: var(--ink-tertiary);
  font-size: 0.82rem;
`;
