import { styled } from "styled-components";

import { Icon } from "@/components/icons";

export const FaqList = styled.div`
  border-top: 1px solid var(--outline);
`;

export const FaqItemRoot = styled.div`
  position: relative;
  border-bottom: 1px solid var(--outline);
`;

export const FaqMark = styled(Icon)<{ $open: boolean }>`
  transform: ${({ $open }) => ($open ? "rotate(45deg)" : "none")};
  transition: transform 480ms var(--ease-out);
`;

export const FaqMarkWrap = styled.span<{ $open: boolean }>`
  display: grid;
  width: 2rem;
  height: 2rem;
  flex-shrink: 0;
  place-items: center;
  border: 1px solid
    ${({ $open }) => ($open ? "rgba(232, 133, 97, 0.5)" : "var(--outline)")};
  border-radius: 50%;
  background: ${({ $open }) => ($open ? "rgba(232, 133, 97, 0.1)" : "transparent")};
  color: ${({ $open }) => ($open ? "var(--accent)" : "var(--ink-tertiary)")};
  transform: ${({ $open }) => ($open ? "scale(1.04)" : "none")};
  transition:
    color var(--dur) var(--ease-out),
    border-color var(--dur) var(--ease-out),
    background-color var(--dur) var(--ease-out),
    transform var(--dur) var(--ease-out);
`;

export const FaqSummary = styled.button<{ $open: boolean }>`
  display: flex;
  width: 100%;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
  padding: 1.4rem 0.2rem;
  border: 0;
  appearance: none;
  background: transparent;
  color: ${({ $open }) => ($open ? "var(--accent)" : "inherit")};
  cursor: pointer;
  font: inherit;
  font-size: var(--step-1);
  letter-spacing: -0.025em;
  text-align: left;
  transition:
    color var(--dur) var(--ease-out),
    padding-inline var(--dur) var(--ease-out);

  &:hover {
    padding-inline: 0.55rem 0.2rem;
    color: var(--accent);
  }

  &:hover ${FaqMarkWrap} {
    border-color: rgba(232, 133, 97, 0.42);
    background: rgba(232, 133, 97, 0.07);
    color: var(--accent);
    transform: scale(1.06);
  }

  &:hover ${FaqMark} {
    transform: ${({ $open }) => ($open ? "rotate(45deg)" : "rotate(12deg)")};
  }

  @media (hover: none) {
    &:hover {
      padding-inline: 0.2rem;
    }
  }
`;

export const FaqPanel = styled.div<{ $open: boolean }>`
  display: grid;
  grid-template-rows: ${({ $open }) => ($open ? "1fr" : "0fr")};
  opacity: ${({ $open }) => ($open ? 1 : 0)};
  visibility: ${({ $open }) => ($open ? "visible" : "hidden")};
  transform: ${({ $open }) => ($open ? "none" : "translateY(-7px)")};
  transition:
    grid-template-rows 560ms var(--ease-out),
    opacity 300ms ease,
    transform 460ms var(--ease-out),
    visibility 0s linear ${({ $open }) => ($open ? "0s" : "560ms")};

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
`;

export const FaqPanelInner = styled.div`
  min-height: 0;
  overflow: hidden;
`;

export const FaqAnswer = styled.p`
  max-width: 62ch;
  padding: 0.05rem 0.55rem 1.65rem;
  color: var(--ink-secondary);
  line-height: 1.65;
`;
