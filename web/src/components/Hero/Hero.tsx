import { useEffect, useRef } from "react";

import { nearestFrame, useFrameSequence } from "@/hooks/useFrameSequence";
import { useIsCompact, usePrefersReducedMotion } from "@/hooks/useMediaQuery";
import { useScrollScrub } from "@/hooks/useScrollScrub";
import { asset } from "@/lib/asset";
import {
  FRAME_COUNT,
  FRAME_COUNT_SM,
  FRAME_DIR_LG,
  FRAME_DIR_SM,
  FRAME_HEIGHT,
  FRAME_HEIGHT_SM,
  FRAME_WIDTH,
  FRAME_WIDTH_SM,
} from "@/lib/site";
import {
  CanvasWrap,
  CueRail,
  DemoCanvas,
  Headline,
  HeadlineSerif,
  HeroSection,
  HeroSticky,
  HeroTop,
  Kicker,
  Poster,
  ScrollCue,
  Subhead,
  Vignette,
} from "./Hero.styles";

export function Hero() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const desiredFrameRef = useRef(0);
  const reduced = usePrefersReducedMotion();
  const compact = useIsCompact();
  const frameCount = compact ? FRAME_COUNT_SM : FRAME_COUNT;
  const sequence = useFrameSequence(
    compact ? FRAME_DIR_SM : FRAME_DIR_LG,
    frameCount,
    !reduced,
  );

  const drawFrame = (index: number) => {
    const canvas = canvasRef.current;
    const frame = nearestFrame(sequence.frames, index);
    if (!canvas || !frame) return;

    const context = canvas.getContext("2d");
    if (!context) return;
    context.drawImage(frame, 0, 0, canvas.width, canvas.height);
  };

  useEffect(() => {
    drawFrame(desiredFrameRef.current);
  }, [sequence.progress]);

  const { ref: sectionRef } = useScrollScrub<HTMLElement>({
    damping: compact ? 0.18 : 0.09,
    onFrame: (eased, raw) => {
      const section = sectionRef.current;
      const clamp01 = (value: number) => Math.min(1, Math.max(0, value));
      const smoothstep = (value: number) => {
        const clamped = clamp01(value);
        return clamped * clamped * (3 - 2 * clamped);
      };

      // Mobile uses distinct beats: zoom first, demo second, then lets the light
      // intro overlap the hero at roughly 68% scroll.
      const focus = compact
        ? smoothstep((eased - 0.08) / 0.26)
        : smoothstep((eased - 0.16) / 0.34);
      const approach = compact
        ? smoothstep((eased - 0.08) / 0.26)
        : smoothstep((eased - 0.15) / 0.38);
      const demoProgress = compact
        ? smoothstep((eased - 0.34) / 0.28)
        : smoothstep(eased / 0.74);
      const frameIndex = Math.round(demoProgress * (frameCount - 1));

      desiredFrameRef.current = frameIndex;
      drawFrame(frameIndex);

      if (section) {
        const copyOpacity = 1 - smoothstep(eased / (compact ? 0.3 : 0.17));
        const chromeOpacity =
          1 - smoothstep((eased - 0.01) / (compact ? 0.28 : 0.16));
        // Mobile still begins with the complete laptop in view, then moves in
        // far enough for the interface on its display to remain readable. It
        // stays low enough for the light intro panel to cover it during handoff.
        const scale = 1 + focus * (compact ? 0.85 : 1.35);
        const lift = focus * (compact ? -6 : -26);

        section.style.setProperty("--hero-scale", scale.toFixed(4));
        section.style.setProperty("--hero-lift", `${lift.toFixed(2)}vh`);
        section.style.setProperty("--hero-copy-y", `${(eased * -48).toFixed(2)}px`);
        section.style.setProperty("--hero-actions-y", `${(eased * 40).toFixed(2)}px`);
        section.style.setProperty("--hero-brightness", (1 + approach * 0.12).toFixed(3));
        section.style.setProperty("--hero-contrast", (1 + approach * 0.06).toFixed(3));
        section.style.setProperty(
          "--hero-exit-opacity",
          compact
            ? "1"
            : (1 - smoothstep((Math.max(eased, raw) - 0.72) / 0.18)).toFixed(4),
        );
        section.style.setProperty("--hero-copy-opacity", copyOpacity.toFixed(4));
        section.style.setProperty("--hero-chrome-opacity", chromeOpacity.toFixed(4));
        section.style.setProperty("--hero-progress", eased.toFixed(4));
      }
    },
  });

  return (
    <HeroSection id="top" ref={sectionRef}>
      <HeroSticky>
        <CanvasWrap>
          <Poster
            src={asset("shots/poster-cutout.webp")}
            alt="AngelNotch expanding out of a MacBook notch and cycling through media controls, clipboard history, a focus timer and system controls."
          />
          {!reduced && (
            <DemoCanvas
              ref={canvasRef}
              $ready={sequence.ready}
              width={compact ? FRAME_WIDTH_SM : FRAME_WIDTH}
              height={compact ? FRAME_HEIGHT_SM : FRAME_HEIGHT}
              aria-hidden="true"
            />
          )}
        </CanvasWrap>
        <Vignette aria-hidden="true" />

        <HeroTop>
          <Kicker>Made for macOS · Free and open source</Kicker>

          <Headline>
            Your Mac, <HeadlineSerif>at a glance.</HeadlineSerif>
          </Headline>

          <Subhead>Media, clipboard, files, focus and controls from the notch.</Subhead>
        </HeroTop>

        <ScrollCue aria-hidden="true">
          <CueRail />
          Scroll
        </ScrollCue>
      </HeroSticky>
    </HeroSection>
  );
}
