import { css, styled } from "styled-components";

import { Icon } from "@/components/icons";

export type SectionTransitionPhase = "idle" | "covering" | "covered" | "revealing";

const transitionVisible = (phase: SectionTransitionPhase) => phase !== "idle";
const transitionCovered = (phase: SectionTransitionPhase) =>
  phase === "covered" || phase === "revealing";

export const SectionTransition = styled.div<{ $phase: SectionTransitionPhase }>`
  position: fixed;
  inset: 0;
  z-index: 160;
  overflow: hidden;
  background:
    radial-gradient(circle at 50% 48%, rgba(243, 237, 227, 0.025), transparent 44%),
    #181816;
  clip-path: ${({ $phase }) =>
    $phase === "revealing"
      ? "inset(0 0 100% 0)"
      : transitionVisible($phase)
        ? "inset(0)"
        : "inset(100% 0 0 0)"};
  pointer-events: ${({ $phase }) => (transitionVisible($phase) ? "auto" : "none")};
  visibility: ${({ $phase }) => (transitionVisible($phase) ? "visible" : "hidden")};
  transition:
    clip-path ${({ $phase }) => ($phase === "revealing" ? "760ms" : "620ms")}
      var(--ease-inout),
    visibility 0s linear ${({ $phase }) => ($phase === "idle" ? "760ms" : "0s")};

  &::before {
    position: absolute;
    inset: 0;
    background:
      radial-gradient(circle at 41% 43%, rgba(232, 133, 97, 0.1), transparent 28%),
      radial-gradient(circle at 60% 58%, rgba(133, 179, 179, 0.075), transparent 31%);
    content: "";
    opacity: ${({ $phase }) => (transitionVisible($phase) ? 1 : 0)};
    transform: scale(${({ $phase }) => (transitionCovered($phase) ? 1.06 : 0.88)});
    transition:
      opacity 380ms ease,
      transform 1300ms var(--ease-out);
  }

`;

export const TransitionDevice = styled.div<{
  $phase: SectionTransitionPhase;
}>`
  position: absolute;
  top: 50%;
  left: 50%;
  width: min(62vw, 720px);
  aspect-ratio: 1.7;
  overflow: hidden;
  border: 1px solid rgba(243, 237, 227, 0.18);
  border-radius: clamp(18px, 2.3vw, 30px) clamp(18px, 2.3vw, 30px)
    clamp(12px, 1.5vw, 20px) clamp(12px, 1.5vw, 20px);
  background:
    radial-gradient(circle at 20% 110%, rgba(232, 133, 97, 0.2), transparent 40%),
    radial-gradient(circle at 82% 105%, rgba(133, 179, 179, 0.16), transparent 40%),
    linear-gradient(145deg, rgba(243, 237, 227, 0.045), rgba(243, 237, 227, 0.012)),
    #0d0d0c;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.11),
    0 70px 150px -80px rgba(0, 0, 0, 1),
    0 36px 90px -70px rgba(232, 133, 97, 0.7);
  opacity: ${({ $phase }) =>
    $phase === "revealing" ? 0.38 : transitionVisible($phase) ? 1 : 0};
  transform: translate(-50%, -50%)
    translateY(${({ $phase }) => ($phase === "covering" ? "8vh" : $phase === "revealing" ? "-7vh" : 0)})
    scale(${({ $phase }) => (transitionCovered($phase) ? 1 : 0.72)});
  transition:
    opacity 540ms ease,
    transform 1200ms var(--ease-out);

  &::before {
    position: absolute;
    inset: clamp(8px, 1vw, 13px);
    border: 1px solid rgba(243, 237, 227, 0.055);
    border-radius: clamp(13px, 1.7vw, 22px);
    background:
      radial-gradient(circle at 50% -10%, rgba(243, 237, 227, 0.055), transparent 34%),
      linear-gradient(180deg, rgba(255, 255, 255, 0.018), transparent 55%);
    content: "";
  }

  &::after {
    position: absolute;
    right: 8%;
    bottom: 9%;
    left: 8%;
    height: 1px;
    background: linear-gradient(90deg, transparent, rgba(243, 237, 227, 0.1), transparent);
    content: "";
  }

  @media (max-width: 760px) {
    width: min(88vw, 590px);
  }
`;

export const TransitionCore = styled.div<{ $phase: SectionTransitionPhase }>`
  position: absolute;
  top: -1px;
  left: 50%;
  display: grid;
  z-index: 2;
  width: clamp(8rem, 17vw, 12rem);
  height: clamp(2.8rem, 5.8vw, 4.2rem);
  place-items: center;
  border: 1px solid rgba(243, 237, 227, 0.2);
  border-top: 0;
  border-radius: 0 0 clamp(20px, 2.6vw, 31px) clamp(20px, 2.6vw, 31px);
  background: #050505;
  box-shadow:
    inset 0 -1px 0 rgba(255, 255, 255, 0.055),
    0 20px 42px -28px rgba(0, 0, 0, 1);
  opacity: ${({ $phase }) => (transitionVisible($phase) ? 1 : 0)};
  transform: translateX(-50%)
    scaleX(${({ $phase }) => (transitionCovered($phase) ? 1 : 0.62)});
  transform-origin: top center;
  transition:
    opacity 320ms ease,
    transform 980ms var(--ease-out);

  &::after {
    position: absolute;
    top: 50%;
    right: 19%;
    width: 5px;
    height: 5px;
    border-radius: 50%;
    background: #151918;
    box-shadow:
      inset 0 0 1px rgba(255, 255, 255, 0.14),
      0 0 7px rgba(133, 179, 179, 0.18);
    content: "";
    transform: translateY(-50%);
  }

  svg {
    width: clamp(2rem, 3.8vw, 2.9rem);
    height: clamp(2rem, 3.8vw, 2.9rem);
    opacity: ${({ $phase }) => ($phase === "revealing" ? 0.5 : 1)};
    transform: translateX(-13%) scale(${({ $phase }) => ($phase === "revealing" ? 0.82 : 1)});
    transition:
      opacity 420ms ease,
      transform 760ms var(--ease-out);
  }
`;

export const TransitionMeta = styled.div<{ $phase: SectionTransitionPhase }>`
  position: absolute;
  right: var(--gutter);
  bottom: clamp(1.5rem, 4vw, 3.25rem);
  left: var(--gutter);
  display: flex;
  align-items: baseline;
  gap: 0.9rem;
  opacity: ${({ $phase }) => (transitionCovered($phase) ? 1 : 0)};
  transform: translateY(${({ $phase }) => (transitionCovered($phase) ? 0 : "18px")});
  transition:
    opacity 420ms ease 120ms,
    transform 680ms var(--ease-out) 80ms;
`;

export const TransitionIndex = styled.span`
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.7rem;
  letter-spacing: 0.1em;
`;

export const TransitionLabel = styled.span`
  color: var(--cream);
  font-size: clamp(1.7rem, 3.5vw, 3.3rem);
  font-weight: 400;
  letter-spacing: -0.045em;
  line-height: 1;
`;

export const TransitionProgress = styled.span<{ $phase: SectionTransitionPhase }>`
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  height: 2px;
  overflow: hidden;
  background: rgba(243, 237, 227, 0.06);

  &::after {
    display: block;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, var(--accent-deep), var(--accent), var(--cyan));
    content: "";
    transform: scaleX(
      ${({ $phase }) => ($phase === "idle" ? 0 : $phase === "covering" ? 0.35 : 1)}
    );
    transform-origin: left;
    transition: transform ${({ $phase }) => ($phase === "covering" ? "620ms" : "760ms")}
      var(--ease-out);
  }
`;

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

export const QuickNavLink = styled.a<{ $active: boolean; $open: boolean; $delay: number }>`
  display: grid;
  grid-template-columns: 2rem 1fr auto;
  min-height: 2.65rem;
  flex: 1;
  align-items: center;
  padding: 0 0.25rem;
  border-bottom: 1px solid var(--outline);
  background-color: transparent;
  color: ${({ $active }) => ($active ? "var(--ink-primary)" : "var(--ink-secondary)")};
  font-size: 0.93rem;
  font-weight: ${({ $active }) => ($active ? 500 : 400)};
  letter-spacing: -0.02em;
  opacity: ${({ $open }) => ($open ? 1 : 0)};
  transform: translateY(${({ $open }) => ($open ? 0 : "7px")});
  transition:
    color var(--dur-fast) ease,
    background-color var(--dur-fast) ease,
    opacity 280ms ease ${({ $delay }) => `${$delay}ms`},
    transform 420ms var(--ease-out) ${({ $delay }) => `${$delay}ms`};

  ${QuickNavIndex},
  ${QuickNavArrow} {
    color: ${({ $active }) => ($active ? "var(--accent)" : undefined)};
  }

  ${QuickNavArrow} {
    transform: none;
  }

  &:hover {
    background-color: rgba(244, 238, 228, 0.035);
    color: var(--ink-primary);
  }

  &:focus-visible {
    outline: 1px solid rgba(232, 133, 97, 0.35);
    outline-offset: -1px;
    background-color: rgba(232, 133, 97, 0.07);
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
    transform: translateX(2px);
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

  &:hover {
    border-color: ${({ $open }) => ($open ? "transparent" : "rgba(232, 133, 97, 0.52)")};
    background: ${({ $open }) => ($open ? "transparent" : "#151310")};
    box-shadow: ${({ $open }) =>
      $open ? "none" : "0 18px 38px -22px rgba(232, 133, 97, 0.62)"};
    transform: ${({ $open }) => ($open ? "none" : "translateY(-3px)")};
  }
`;
