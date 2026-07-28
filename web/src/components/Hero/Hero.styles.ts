import { css, keyframes, styled } from "styled-components";

const cueMotion = keyframes`
  0% {
    transform: translateY(-120%);
  }

  60%,
  100% {
    transform: translateY(280%);
  }
`;

export const HeroSection = styled.section`
  --hero-scale: 1;
  --hero-lift: 0vh;
  --hero-copy-y: 0px;
  --hero-actions-y: 0px;
  --hero-copy-opacity: 1;
  --hero-chrome-opacity: 1;
  --hero-progress: 0;
  --hero-brightness: 1;
  --hero-contrast: 1;
  --hero-exit-opacity: 1;

  position: relative;
  height: 330vh;
  margin-bottom: -100vh;

  @media (max-width: 760px) {
    height: 320svh;
    margin-bottom: -70svh;
  }

  @media (prefers-reduced-motion: reduce) {
    height: auto;
    margin-bottom: 0;
  }
`;

export const HeroSticky = styled.div`
  position: fixed;
  inset: 0;
  top: 0;
  z-index: 0;
  display: grid;
  height: 100vh;
  min-height: 640px;
  grid-template-rows: auto minmax(0, 1fr) auto;
  overflow: clip;
  opacity: var(--hero-exit-opacity);
  pointer-events: none;
  will-change: opacity;

  @media (max-width: 760px) {
    position: sticky;
    height: 100svh;
    min-height: 0;
  }

  @media (prefers-reduced-motion: reduce) {
    position: relative;
    height: auto;
    min-height: 0;
    padding-bottom: 3rem;
  }
`;

export const CanvasWrap = styled.div`
  position: absolute;
  top: clamp(31vh, 16.5rem, 37vh);
  left: 50%;
  z-index: 1;
  width: min(96vw, 96vh);
  height: min(64vh, 64vw);
  transform: translate3d(-50%, var(--hero-lift), 0) scale(var(--hero-scale));
  transform-origin: 50% 11%;
  will-change: transform;

  @media (max-width: 760px) {
    top: 43svh;
    width: min(94vw, 27rem);
    height: min(62.67vw, 18rem);
    transform-origin: 50% 9%;
  }

  @media (prefers-reduced-motion: reduce) {
    position: relative;
    inset: auto;
    padding: 2rem var(--gutter) 0;
    transform: none;
  }
`;

const demoStyles = css`
  position: absolute;
  inset: 0;
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
  opacity: 0;
  filter:
    drop-shadow(0 30px 42px rgba(0, 0, 0, 0.5))
    brightness(var(--hero-brightness))
    contrast(var(--hero-contrast));
  transition: opacity 700ms var(--ease-out);
  will-change: filter;

  @media (max-width: 760px) {
    filter: brightness(var(--hero-brightness)) contrast(var(--hero-contrast));
    will-change: opacity;
  }

  @media (prefers-reduced-motion: reduce) {
    opacity: 1;
  }
`;

export const Poster = styled.img`
  ${demoStyles}
  opacity: 1;
`;

export const DemoCanvas = styled.canvas<{ $ready: boolean }>`
  ${demoStyles}
  z-index: 1;
  opacity: ${({ $ready }) => ($ready ? 1 : 0)};
`;

export const Vignette = styled.div`
  position: absolute;
  inset: 0;
  z-index: 2;
  background:
    linear-gradient(180deg, var(--canvas) 0%, rgba(9, 9, 8, 0.72) 24%, transparent 43%),
    linear-gradient(180deg, transparent 78%, rgba(9, 9, 8, 0.5) 94%, var(--canvas) 100%);
  opacity: var(--hero-chrome-opacity);
  pointer-events: none;
  will-change: opacity;

  @media (prefers-reduced-motion: reduce) {
    display: none;
  }
`;

export const HeroTop = styled.div`
  position: relative;
  z-index: 3;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.9rem;
  padding: calc(clamp(5rem, 3.4rem + 5vh, 7rem) + 1.1rem) var(--gutter) 0;
  opacity: var(--hero-copy-opacity);
  text-align: center;
  transform: translate3d(0, var(--hero-copy-y), 0);
  will-change: opacity, transform;

  @media (max-width: 760px) {
    gap: 0.72rem;
    padding: clamp(5.5rem, 12svh, 6.5rem) 1.2rem 0;
  }

  @media (prefers-reduced-motion: reduce) {
    transform: none;
  }
`;

export const Kicker = styled.p`
  color: var(--ink-tertiary);
  font-family: var(--font-mono);
  font-size: 0.68rem;
  font-weight: 500;
  line-height: 1.4;
  letter-spacing: 0.11em;
  text-transform: uppercase;

  @media (max-width: 760px) {
    font-size: 0.62rem;
  }
`;

export const Headline = styled.h1`
  max-width: 16ch;
  font-size: clamp(3rem, 1.6rem + 6.4vw, 6.6rem);
  font-weight: 500;
  line-height: 0.86;
  letter-spacing: -0.052em;

  @media (max-width: 760px) {
    max-width: 9ch;
    font-size: clamp(2.85rem, 13vw, 3.7rem);
    line-height: 0.88;
  }
`;

export const HeadlineSerif = styled.span`
  padding-right: 0.06em;
  font-family: var(--font-serif);
  font-style: italic;
  font-weight: 400;
  letter-spacing: -0.03em;
`;

export const Subhead = styled.p`
  max-width: 46ch;
  color: var(--ink-secondary);
  font-size: var(--step-1);
  line-height: 1.45;
  letter-spacing: -0.015em;
  text-wrap: balance;

  @media (max-width: 760px) {
    max-width: 28ch;
    font-size: 0.96rem;
    line-height: 1.42;
  }
`;

export const ScrollCue = styled.p`
  position: absolute;
  right: clamp(1rem, 0.4rem + 1.6vw, 2.2rem);
  bottom: clamp(1.4rem, 0.8rem + 2vh, 2.4rem);
  z-index: 4;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  color: var(--ink-faint);
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  opacity: var(--hero-chrome-opacity);

  @media (max-width: 760px) {
    right: 0.9rem;
    bottom: 1rem;
  }

  @media (prefers-reduced-motion: reduce) {
    display: none;
  }
`;

export const CueRail = styled.span`
  position: relative;
  width: 1px;
  height: 26px;
  overflow: hidden;
  background: var(--outline);

  &::after {
    position: absolute;
    inset: 0 0 auto;
    height: 40%;
    background: var(--accent);
    content: "";
    animation: ${cueMotion} 2.4s var(--ease-inout) infinite;
  }
`;
