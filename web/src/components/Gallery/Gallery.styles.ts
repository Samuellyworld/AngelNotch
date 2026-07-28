import { css, styled } from "styled-components";

import { Section } from "@/components/ui";

const staticSticky = css`
  position: relative;
  display: block;
  height: auto;
  min-height: 0;
  overflow: visible;
  padding-block: 0;
`;

const staticHeader = css`
  position: relative;
  top: auto;
  inset-inline: auto;
  margin-inline: var(--gutter);
  padding-bottom: 1rem;
`;

const staticViewport = css`
  overflow-x: auto;
  overscroll-behavior-inline: contain;
  scroll-padding-inline: var(--gutter);
  scroll-snap-type: x mandatory;
  scrollbar-width: none;

  &::-webkit-scrollbar {
    display: none;
  }
`;

const staticTrack = css`
  gap: 1.25rem;
  padding-inline: var(--gutter);
  transform: none !important;
  will-change: auto;
`;

export const GallerySection = styled(Section)`
  --ink-primary: #171613;
  --ink-secondary: rgba(23, 22, 19, 0.64);
  --ink-tertiary: rgba(23, 22, 19, 0.44);
  --ink-faint: rgba(23, 22, 19, 0.28);
  --outline: rgba(23, 22, 19, 0.13);
  --outline-strong: rgba(23, 22, 19, 0.22);
  --surface: rgba(23, 22, 19, 0.06);

  background:
    radial-gradient(70% 20% at 50% 0%, rgba(232, 133, 97, 0.065), transparent 72%),
    #f1eee8;
  color: #171613;
`;

export const Shot = styled.img`
  width: auto;
  max-width: 88%;
  max-height: 82%;
  height: auto;
  border: 1px solid rgba(243, 237, 227, 0.12);
  border-radius: clamp(13px, 1.4vw, 19px);
  box-shadow: 0 38px 80px -42px rgba(0, 0, 0, 0.95);
  filter: saturate(0.9) brightness(0.92);
  object-fit: contain;
  transform: translateY(4px) scale(0.985);
  transition:
    transform 760ms var(--ease-out),
    filter 760ms var(--ease-out),
    box-shadow 760ms var(--ease-out);

  @media (max-width: 560px) {
    max-width: 91%;
    max-height: 79%;
    border-radius: 12px;
  }

  @media (prefers-reduced-motion: reduce) {
    filter: none;
    transform: none;
  }
`;

export const Visual = styled.div`
  position: relative;
  display: grid;
  height: clamp(300px, 42svh, 430px);
  place-items: center;
  overflow: hidden;
  border: 1px solid rgba(23, 22, 19, 0.14);
  border-radius: var(--r-card);
  background:
    radial-gradient(85% 75% at 50% 40%, rgba(232, 133, 97, 0.16), transparent 68%),
    #191613;
  box-shadow: 0 34px 78px -52px rgba(23, 22, 19, 0.62);

  @media (max-width: 840px) {
    height: clamp(320px, 68vw, 500px);
  }

  @media (max-width: 560px) {
    height: clamp(270px, 73vw, 360px);
    border-radius: 18px;
  }
`;

export const Counter = styled.span`
  position: absolute;
  top: 1rem;
  left: 1rem;
  z-index: 2;
  display: grid;
  width: 2.35rem;
  height: 2.35rem;
  place-items: center;
  border: 1px solid rgba(243, 237, 227, 0.17);
  border-radius: 50%;
  background: rgba(9, 9, 8, 0.3);
  color: rgba(243, 237, 227, 0.58);
  font-family: var(--font-mono);
  font-size: 0.65rem;
  backdrop-filter: blur(10px);
`;

export const Caption = styled.figcaption`
  display: grid;
  grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
  gap: 1.2rem;
  padding: 1.05rem 0.1rem 0;

  @media (max-width: 560px) {
    grid-template-columns: 1fr;
    gap: 0.55rem;
    padding-bottom: 1.8rem;
  }
`;

export const SurfaceKind = styled.p`
  color: var(--accent-deep);
  font-family: var(--font-mono);
  font-size: 0.65rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
`;

export const CardTitle = styled.h3`
  margin-top: 0.2rem;
  font-size: var(--step-2);
  letter-spacing: -0.045em;

  @media (max-width: 560px) {
    font-size: 1.45rem;
  }
`;

export const Description = styled.p`
  max-width: 34ch;
  color: var(--ink-secondary);
  font-size: var(--step-0);
  line-height: 1.5;

  @media (max-width: 560px) {
    font-size: 0.9rem;
  }
`;

export const GalleryCard = styled.figure<{ $static: boolean }>`
  width: min(54vw, 760px);
  min-width: 0;
  flex: 0 0 auto;

  &:nth-child(even) {
    width: min(48vw, 680px);
  }

  &:nth-child(3) ${Visual} {
    background:
      radial-gradient(90% 80% at 50% 42%, rgba(209, 171, 107, 0.2), transparent 68%),
      #191713;
  }

  &:nth-child(4) ${Visual} {
    background:
      radial-gradient(90% 80% at 50% 42%, rgba(163, 148, 186, 0.22), transparent 68%),
      #17151a;
  }

  &:nth-child(5) ${Visual} {
    background:
      radial-gradient(90% 80% at 50% 42%, rgba(122, 153, 194, 0.22), transparent 68%),
      #14171b;
  }

  &:hover ${Shot} {
    box-shadow: 0 48px 90px -40px rgba(0, 0, 0, 1);
    filter: none;
    transform: translateY(-5px) scale(1.012);
  }

  ${({ $static }) =>
    $static &&
    css`
      width: min(84vw, 580px);
      scroll-snap-align: start;
      scroll-snap-stop: always;

      &:nth-child(even) {
        width: min(84vw, 580px);
      }
    `}

  @media (max-width: 840px) {
    width: min(84vw, 580px);
    scroll-snap-align: start;
    scroll-snap-stop: always;

    &:nth-child(even) {
      width: min(84vw, 580px);
    }
  }

  @media (max-width: 560px) {
    width: min(84vw, 390px);

    &:nth-child(even) {
      width: min(84vw, 390px);
    }
  }
`;

export const Track = styled.div<{ $static: boolean }>`
  display: flex;
  width: max-content;
  gap: clamp(1.25rem, 2.4vw, 2.4rem);
  padding-inline: max(var(--gutter), calc((100vw - var(--max)) / 2));
  will-change: transform;

  ${({ $static }) => $static && staticTrack}

  @media (max-width: 840px) {
    ${staticTrack}
  }
`;

export const TrackViewport = styled.div<{ $static: boolean }>`
  width: 100%;
  min-height: 0;
  overflow: hidden;

  ${({ $static }) => $static && staticViewport}

  @media (max-width: 840px) {
    ${staticViewport}
  }
`;

export const ReelHeader = styled.div<{ $static: boolean }>`
  position: absolute;
  top: clamp(6.5rem, 12vh, 8rem);
  inset-inline: max(var(--gutter), calc((100vw - var(--max)) / 2));
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: var(--ink-tertiary);
  font-family: var(--font-mono);
  font-size: var(--step--1);
  letter-spacing: 0.06em;
  text-transform: uppercase;

  ${({ $static }) => $static && staticHeader}

  @media (max-width: 840px) {
    ${staticHeader}
  }
`;

export const ScrollHint = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;

  span {
    color: var(--accent-deep);
    font-size: 1rem;
  }
`;

export const Sticky = styled.div<{ $static: boolean }>`
  position: sticky;
  top: 0;
  display: flex;
  height: 100svh;
  align-items: center;
  overflow: hidden;
  padding-block: clamp(6.5rem, 12vh, 8rem) clamp(1.5rem, 4vh, 3rem);
  background:
    radial-gradient(60% 60% at 50% 48%, rgba(232, 133, 97, 0.07), transparent 76%),
    #f1eee8;

  ${({ $static }) => $static && staticSticky}

  @media (max-width: 840px) {
    ${staticSticky}
  }
`;

export const Scene = styled.div<{ $static: boolean }>`
  width: 100vw;
  height: ${({ $static }) => ($static ? "auto" : "430svh")};
  margin-left: calc(50% - 50vw);

  @media (max-width: 840px) {
    height: auto;
  }
`;
