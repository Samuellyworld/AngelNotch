import { css, styled } from "styled-components";

import { Icon } from "@/components/icons";

export const QuickNavRoot = styled.div`
  position: fixed;
  right: clamp(0.8rem, 1.8vw, 1.5rem);
  bottom: clamp(0.8rem, 1.8vw, 1.5rem);
  z-index: 180;
  width: min(18.5rem, calc(100vw - 1.6rem));
  height: min(31rem, calc(100svh - 1.6rem));
  pointer-events: none;

  @media (max-width: 520px) {
    right: 0.7rem;
    bottom: 0.7rem;
    width: min(19rem, calc(100vw - 1.4rem));
    height: min(30rem, calc(100svh - 1.4rem));
  }
`;

export const QuickNavPanel = styled.div<{ $open: boolean }>`
  position: absolute;
  inset: 0;
  overflow: hidden;
  border: 1px solid var(--outline-strong);
  border-radius: ${({ $open }) => ($open ? "24px" : "24px")};
  background: rgba(12, 12, 10, 0.96);
  box-shadow: ${({ $open }) =>
    $open ? "0 28px 90px -28px rgba(0, 0, 0, 0.9)" : "0 26px 70px -36px rgba(0, 0, 0, 0.95)"};
  clip-path: ${({ $open }) =>
    $open
      ? "inset(0 round 24px)"
      : "inset(calc(100% - 3.5rem) 0 0 calc(100% - 3.5rem) round 18px)"};
  pointer-events: ${({ $open }) => ($open ? "auto" : "none")};
  transition:
    clip-path 580ms var(--ease-out),
    border-radius 580ms var(--ease-out),
    box-shadow 580ms var(--ease-out);
`;

export const QuickNavContent = styled.div<{ $open: boolean }>`
  display: flex;
  height: 100%;
  flex-direction: column;
  padding: 1.2rem 1rem 4.7rem;
  opacity: ${({ $open }) => ($open ? 1 : 0)};
  visibility: ${({ $open }) => ($open ? "visible" : "hidden")};
  transform: translateY(${({ $open }) => ($open ? 0 : "15px")});
  transition: ${({ $open }) =>
    $open
      ? "opacity 260ms ease 110ms, transform 460ms var(--ease-out) 90ms, visibility 0s linear"
      : "opacity 190ms ease, transform 420ms var(--ease-out), visibility 0s linear 420ms"};
`;

export const QuickNavHeading = styled.div`
  display: flex;
  min-height: 2.65rem;
  align-items: center;
  justify-content: space-between;
  padding: 0 0.25rem 0.75rem;
  border-bottom: 1px solid var(--outline);
`;

const quickNavMeta = css`
  font-family: var(--font-mono);
  font-size: 0.67rem;
  line-height: 1;
  letter-spacing: 0.08em;
  text-transform: uppercase;
`;

export const QuickNavEyebrow = styled.span`
  ${quickNavMeta}
  color: var(--ink-secondary);
`;

export const QuickNavCount = styled.span`
  ${quickNavMeta}
  color: var(--accent);
`;

export const QuickNavLinks = styled.nav`
  display: flex;
  flex: 1;
  flex-direction: column;
`;

export const QuickNavIndex = styled.span`
  ${quickNavMeta}
  color: var(--ink-faint);
  transition: color var(--dur-fast) ease;
`;

export const QuickNavArrow = styled(Icon)`
  color: var(--ink-tertiary);
  transition:
    color var(--dur-fast) ease,
    transform var(--dur-fast) var(--ease-out);
`;

export const QuickNavLink = styled.a<{ $open: boolean; $delay: number }>`
  display: grid;
  grid-template-columns: 2rem 1fr auto;
  min-height: 2.65rem;
  flex: 1;
  align-items: center;
  border-bottom: 1px solid var(--outline);
  color: var(--ink-secondary);
  font-size: 0.93rem;
  letter-spacing: -0.02em;
  opacity: ${({ $open }) => ($open ? 1 : 0)};
  transform: translateY(${({ $open }) => ($open ? 0 : "7px")});
  transition:
    color var(--dur-fast) ease,
    background-color var(--dur-fast) ease,
    opacity 280ms ease ${({ $delay }) => `${$delay}ms`},
    transform 420ms var(--ease-out) ${({ $delay }) => `${$delay}ms`};

  &:hover,
  &:focus-visible {
    background: linear-gradient(90deg, rgba(232, 133, 97, 0.08), transparent 75%);
    color: var(--ink-primary);
  }

  &:hover ${QuickNavIndex},
  &:focus-visible ${QuickNavIndex},
  &:hover ${QuickNavArrow},
  &:focus-visible ${QuickNavArrow} {
    color: var(--accent);
  }

  &:hover ${QuickNavArrow},
  &:focus-visible ${QuickNavArrow} {
    transform: translateX(3px);
  }

  @media (prefers-reduced-motion: reduce) {
    opacity: 1;
    transform: none;
  }
`;

export const ToggleMark = styled.span`
  position: relative;
  width: 19px;
  height: 15px;
`;

export const ToggleLine = styled.span<{
  $open: boolean;
  $position: "top" | "middle" | "bottom";
}>`
  position: absolute;
  left: 0;
  width: ${({ $position }) => ($position === "middle" ? "13px" : "19px")};
  height: 1px;
  border-radius: 1px;
  background: currentColor;
  opacity: ${({ $open, $position }) => ($open && $position === "middle" ? 0 : 1)};
  top: ${({ $open, $position }) => {
    if ($open && $position !== "middle") return "7px";
    if ($position === "top") return "1px";
    if ($position === "middle") return "7px";
    return "13px";
  }};
  transform: ${({ $open, $position }) => {
    if (!$open) return "none";
    if ($position === "top") return "rotate(45deg)";
    if ($position === "middle") return "translateX(6px)";
    return "rotate(-45deg)";
  }};
  transform-origin: center;
  transition:
    top 440ms var(--ease-out),
    transform 440ms var(--ease-out),
    opacity 190ms ease;
`;

export const QuickNavToggle = styled.button<{ $open: boolean }>`
  position: absolute;
  right: 0;
  bottom: 0;
  z-index: 2;
  display: grid;
  width: 3.5rem;
  height: 3.5rem;
  place-items: center;
  border: 1px solid ${({ $open }) => ($open ? "transparent" : "var(--outline-strong)")};
  border-radius: ${({ $open }) => ($open ? "0 0 23px" : "18px")};
  background: ${({ $open }) => ($open ? "transparent" : "rgba(16, 16, 14, 0.96)")};
  color: var(--cream);
  pointer-events: auto;
  transform: none;
  transition:
    border-radius 500ms var(--ease-out),
    border-color var(--dur-fast) ease,
    background-color var(--dur-fast) ease;

  &::after {
    position: absolute;
    right: 7px;
    bottom: 7px;
    width: 4px;
    height: 4px;
    border-radius: 50%;
    background: var(--accent);
    content: "";
    opacity: ${({ $open }) => ($open ? 0 : 1)};
    transform: ${({ $open }) => ($open ? "scale(0)" : "none")};
    transition:
      transform 500ms var(--ease-out),
      opacity 220ms ease;
  }

  &:hover {
    border-color: ${({ $open }) => ($open ? "transparent" : "rgba(232, 133, 97, 0.52)")};
    background: ${({ $open }) => ($open ? "transparent" : "#151310")};
    box-shadow: ${({ $open }) =>
      $open ? "none" : "0 18px 38px -22px rgba(232, 133, 97, 0.62)"};
    transform: ${({ $open }) => ($open ? "none" : "translateY(-3px)")};
  }
`;
