import { ReactLenis } from "lenis/react";
import "lenis/dist/lenis.css";

import { usePrefersReducedMotion } from "@/hooks/useMediaQuery";

export const SCROLL_DURATION_SECONDS = 1.5;

export const easeOutExpo = (progress: number) =>
  progress >= 1 ? 1 : 1 - Math.pow(2, -10 * progress);

export function SmoothScroll() {
  const reducedMotion = usePrefersReducedMotion();

  if (reducedMotion) return null;

  return (
    <ReactLenis
      root
      options={{
        autoRaf: true,
        duration: SCROLL_DURATION_SECONDS,
        easing: easeOutExpo,
        smoothWheel: true,
        syncTouch: false,
        touchMultiplier: 1.5,
        anchors: false,
      }}
    />
  );
}
