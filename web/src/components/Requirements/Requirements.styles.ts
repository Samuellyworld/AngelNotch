import { styled } from "styled-components";

import { Icon } from "@/components/icons";
import { Reveal } from "@/components/ui";

export const RequirementsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1px;
  overflow: hidden;
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background: var(--outline);
`;

export const RequirementCard = styled(Reveal)`
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
  padding: clamp(1.4rem, 1rem + 1.2vw, 2rem);
  background: var(--canvas);
`;

export const RequirementIcon = styled(Icon)`
  color: var(--accent);
`;

export const RequirementLabel = styled.h3`
  font-size: var(--step-1);
  letter-spacing: -0.03em;
`;

export const RequirementDetail = styled.p`
  color: var(--ink-secondary);
  font-size: 0.9rem;
  line-height: 1.55;
`;
