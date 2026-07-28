import { createGlobalStyle, styled } from "styled-components";

export const GlobalStyles = createGlobalStyle`
  :root {
    --canvas: #090908;
    --canvas-raised: #0f0f0d;
    --surface: rgba(243, 237, 227, 0.055);
    --surface-quiet: rgba(243, 237, 227, 0.03);
    --surface-raised: rgba(243, 237, 227, 0.085);
    --outline: rgba(243, 237, 227, 0.1);
    --outline-strong: rgba(243, 237, 227, 0.18);

    --cream: #f3ede3;
    --ink-primary: var(--cream);
    --ink-secondary: rgba(243, 237, 227, 0.58);
    --ink-tertiary: rgba(243, 237, 227, 0.36);
    --ink-faint: rgba(243, 237, 227, 0.22);

    --accent: #e88561;
    --accent-deep: #c2634d;
    --cyan: #85b3b3;
    --blue: #7a99c2;
    --mint: #94b39e;
    --sun: #d1ab6b;
    --violet: #a394ba;
    --spotify: #1fd661;

    --font-sans:
      "Geist", ui-sans-serif, -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
    --font-mono: "Geist Mono", ui-monospace, "SF Mono", Menlo, monospace;
    --font-serif: "Instrument Serif", "Iowan Old Style", Georgia, serif;

    --step--1: clamp(0.78rem, 0.75rem + 0.12vw, 0.84rem);
    --step-0: clamp(0.94rem, 0.9rem + 0.2vw, 1.05rem);
    --step-1: clamp(1.12rem, 1.02rem + 0.44vw, 1.35rem);
    --step-2: clamp(1.5rem, 1.24rem + 1.15vw, 2.1rem);
    --step-3: clamp(2.1rem, 1.6rem + 2.2vw, 3.4rem);
    --step-4: clamp(2.8rem, 1.7rem + 4.9vw, 5.6rem);
    --step-5: clamp(3.4rem, 1.4rem + 8.6vw, 8.5rem);

    --gutter: clamp(1.25rem, 0.6rem + 2.8vw, 4rem);
    --section-y: clamp(4rem, 2.75rem + 4vw, 7.5rem);
    --measure: 34ch;
    --max: 1320px;

    --r-compact: 20px;
    --r-expanded: 34px;
    --r-card: 22px;
    --r-pill: 999px;

    --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
    --ease-inout: cubic-bezier(0.65, 0, 0.35, 1);
    --dur-fast: 180ms;
    --dur: 340ms;
    --dur-slow: 720ms;
  }

  *,
  *::before,
  *::after {
    box-sizing: border-box;
  }

  html {
    -webkit-text-size-adjust: 100%;
    scroll-behavior: auto;
    scroll-padding-top: 6rem;
  }

  body {
    margin: 0;
    overflow-x: hidden;
    background: var(--canvas);
    color: var(--ink-primary);
    font-family: var(--font-sans);
    font-size: var(--step-0);
    font-weight: 400;
    line-height: 1.6;
    letter-spacing: -0.01em;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-rendering: optimizeLegibility;
  }

  h1,
  h2,
  h3,
  h4,
  p,
  figure,
  blockquote,
  dl,
  dd {
    margin: 0;
  }

  h1,
  h2,
  h3,
  h4 {
    font-weight: 500;
    line-height: 0.98;
    letter-spacing: -0.035em;
    text-wrap: balance;
  }

  ul,
  ol {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  a {
    color: inherit;
    text-decoration: none;
  }

  img,
  svg,
  video,
  canvas {
    display: block;
    max-width: 100%;
  }

  button {
    border: 0;
    background: none;
    color: inherit;
    font: inherit;
    cursor: pointer;
  }

  @media (hover: hover) and (pointer: fine) {
    html.custom-cursor-active,
    html.custom-cursor-active * {
      cursor: none !important;
    }
  }

  ::selection {
    background: var(--accent);
    color: #1a0d07;
  }

  :focus-visible {
    border-radius: 6px;
    outline: 2px solid var(--accent);
    outline-offset: 3px;
  }

  @media (prefers-reduced-motion: reduce) {
    html {
      scroll-behavior: auto;
    }

    *,
    *::before,
    *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }

  @media (max-width: 760px) {
    :root {
      --gutter: 1.1rem;
      --section-y: 4.5rem;
      --r-card: 18px;
    }

    html {
      scroll-padding-top: 5rem;
    }
  }
`;

export const Shell = styled.div`
  width: 100%;
  max-width: var(--max);
  margin-inline: auto;
  padding-inline: var(--gutter);
`;

export const Serif = styled.span`
  font-family: var(--font-serif);
  font-style: italic;
  font-weight: 400;
  letter-spacing: -0.015em;
`;

export const Mono = styled.span`
  font-family: var(--font-mono);
  font-size: var(--step--1);
  letter-spacing: 0.06em;
  text-transform: uppercase;
`;

export const SkipLink = styled.a`
  position: fixed;
  top: 0.6rem;
  left: 50%;
  z-index: 200;
  padding: 0.6rem 1.1rem;
  border: 1px solid var(--outline-strong);
  border-radius: var(--r-pill);
  background: var(--canvas-raised);
  font-size: 0.85rem;
  transform: translate(-50%, -180%);
  transition: transform var(--dur) var(--ease-out);

  &:focus-visible {
    transform: translate(-50%, 0);
  }
`;

export const Grain = styled.div`
  position: fixed;
  inset: -50%;
  z-index: 90;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='140' height='140'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3'/%3E%3C/filter%3E%3Crect width='140' height='140' filter='url(%23n)'/%3E%3C/svg%3E");
  mix-blend-mode: overlay;
  opacity: 0.13;
  pointer-events: none;

  @media (max-width: 760px) {
    display: none;
  }
`;
