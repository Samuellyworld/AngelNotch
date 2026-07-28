import { useEffect, useRef, useState } from "react";

type Options = {
  /** How quickly the eased value chases the raw scroll position, 0–1 per 60Hz frame. */
  damping?: number;
  /** Number of discrete stages to report back to React. */
  stages?: number;
  /** Called every animation frame with the eased progress. */
  onFrame: (eased: number, raw: number) => void;
};

const clamp = (value: number) => (value < 0 ? 0 : value > 1 ? 1 : value);

/**
 * Turns the scroll position over a tall pinned section into a 0–1 value.
 *
 * Scroll never gets written to here: the visitor remains completely in control.
 * A passive listener records the requested position and a short animation-frame
 * settle makes wheel input feel continuous. Once the image catches the user's
 * scroll position, the loop stops instead of running for the lifetime of the page.
 */
export function useScrollScrub<T extends HTMLElement>({
  damping = 0.14,
  stages = 0,
  onFrame,
}: Options) {
  const ref = useRef<T>(null);
  const frameRef = useRef(onFrame);
  const [stage, setStage] = useState(0);
  frameRef.current = onFrame;

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    let raf = 0;
    let last = performance.now();
    let eased = 0;
    let target = 0;
    let currentStage = -1;
    let running = false;

    const measure = () => {
      const rect = node.getBoundingClientRect();
      const travel = node.offsetHeight - window.innerHeight;
      target = travel > 0 ? clamp(-rect.top / travel) : 0;
    };

    const draw = (now: number) => {
      const delta = Math.min(now - last, 64);
      last = now;

      // Frame-rate-independent exponential smoothing.
      const factor = 1 - Math.pow(1 - damping, delta / (1000 / 60));
      eased += (target - eased) * factor;
      if (Math.abs(target - eased) < 0.00025) eased = target;

      frameRef.current(eased, target);

      if (stages > 0) {
        const next = Math.min(stages - 1, Math.floor(eased * stages));
        if (next !== currentStage) {
          currentStage = next;
          setStage(next);
        }
      }

      if (eased !== target) {
        raf = requestAnimationFrame(draw);
      } else {
        running = false;
      }
    };

    const update = () => {
      measure();
      if (running) return;
      running = true;
      last = performance.now();
      raf = requestAnimationFrame(draw);
    };

    measure();
    eased = target;
    frameRef.current(eased, target);
    window.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update, { passive: true });

    return () => {
      window.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
      cancelAnimationFrame(raf);
    };
  }, [damping, stages]);

  return { ref, stage };
}
