import { styled } from "styled-components";

import { Icon } from "@/components/icons";
import { Reveal } from "@/components/ui";

export const PrivacyCard = styled(Reveal)`
  position: relative;
  padding: clamp(1.8rem, 1rem + 3.5vw, 4rem);
  border: 1px solid var(--outline);
  border-radius: clamp(20px, 1rem + 1.4vw, 30px);
  background:
    radial-gradient(90% 120% at 12% 0%, rgba(148, 179, 158, 0.13), transparent 60%),
    radial-gradient(65% 100% at 100% 100%, rgba(232, 133, 97, 0.08), transparent 72%),
    var(--canvas-raised);
  box-shadow: 0 34px 90px -65px rgba(0, 0, 0, 1);

  @media (max-width: 600px) {
    padding: 1.25rem;
  }
`;

export const PrivacyGrid = styled.div`
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: clamp(2rem, 1rem + 3vw, 4rem);

  @media (max-width: 900px) {
    grid-template-columns: 1fr;
  }

  @media (max-width: 600px) {
    gap: 2rem;
  }
`;

export const PrivacyTitle = styled.h2`
  max-width: 16ch;
  font-size: var(--step-3);
`;

export const PrivacyLede = styled.p`
  max-width: 44ch;
  margin-top: 1.2rem;
  color: var(--ink-secondary);
  line-height: 1.6;
`;

export const Claims = styled.ul`
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 1.6rem;
`;

export const Claim = styled.li`
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.45rem 0.85rem;
  border: 1px solid rgba(148, 179, 158, 0.24);
  border-radius: var(--r-pill);
  background: rgba(148, 179, 158, 0.06);
  color: var(--mint);
  font-size: 0.84rem;
  letter-spacing: -0.01em;
  transition:
    transform var(--dur-fast) var(--ease-out),
    border-color var(--dur-fast) var(--ease-out),
    background-color var(--dur-fast) var(--ease-out);

  &:hover {
    border-color: rgba(148, 179, 158, 0.42);
    background: rgba(148, 179, 158, 0.11);
    transform: translateY(-2px);
  }

  @media (hover: none) {
    &:hover {
      transform: none;
    }
  }
`;

export const PrivacyKicker = styled.p`
  margin-bottom: 0.9rem;
  color: var(--ink-faint);
  font-family: var(--font-mono);
  font-size: var(--step--1);
  letter-spacing: 0.06em;
  text-transform: uppercase;
`;

export const Permissions = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1px;
  overflow: hidden;
  border: 1px solid var(--outline);
  border-radius: 16px;
  background: var(--outline);
`;

export const PermissionIcon = styled(Icon)`
  flex-shrink: 0;
  margin-top: 0.1rem;
  color: var(--ink-tertiary);
  transition: color var(--dur) var(--ease-out);
`;

export const Permission = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.85rem;
  padding: 0.95rem 1.1rem;
  background: var(--canvas-raised);
  transition:
    background-color var(--dur) var(--ease-out),
    padding-left var(--dur) var(--ease-out);

  &:hover {
    padding-left: 1.35rem;
    background: color-mix(in srgb, var(--canvas-raised) 88%, var(--mint));
  }

  &:hover ${PermissionIcon} {
    color: var(--mint);
  }

  @media (max-width: 600px) {
    padding: 0.85rem;

    &:hover {
      padding-left: 0.85rem;
    }
  }

  @media (hover: none) {
    &:hover {
      transform: none;
    }
  }
`;

export const PermissionName = styled.p`
  font-size: 0.95rem;
  letter-spacing: -0.02em;
`;

export const PermissionPurpose = styled.p`
  color: var(--ink-tertiary);
  font-size: 0.85rem;
  line-height: 1.5;
`;

export const PrivacyNote = styled.p`
  max-width: 52ch;
  margin-top: 1.4rem;
  color: var(--ink-tertiary);
  font-size: 0.87rem;
  line-height: 1.6;
`;
