import { useEffect, useRef, useState } from "react";

import { asset } from "@/lib/asset";

type Sequence = {
  /** Already-decoded frames, indexed from 0. Holes are expected while loading. */
  frames: (HTMLImageElement | undefined)[];
  /** 0–1, how much of the sequence has decoded. */
  progress: number;
  /** True once enough frames exist to scrub without visible gaps. */
  ready: boolean;
};

const PASSES = [8, 4, 2, 1] as const;

/**
 * Loads a numbered image sequence in widening passes, starting with every 8th frame
 * before filling the gaps, so the hero becomes scrubbable after a fraction of the bytes
 * have arrived and sharpens as the rest land. Images are decoded off the main
 * thread where the browser supports it, which keeps the first scroll smooth.
 */
export function useFrameSequence(
  dir: string,
  count: number,
  enabled = true,
): Sequence {
  const framesRef = useRef<(HTMLImageElement | undefined)[]>([]);
  const [progress, setProgress] = useState(0);
  const [ready, setReady] = useState(false);

  if (framesRef.current.length !== count) {
    framesRef.current = new Array<HTMLImageElement | undefined>(count);
  }

  useEffect(() => {
    if (!enabled || count === 0) return;

    let cancelled = false;
    let decoded = 0;
    const seen = new Set<number>();

    const load = (index: number) =>
      new Promise<void>((resolve) => {
        const image = new Image();
        image.decoding = "async";
        image.src = asset(`${dir}/${String(index + 1).padStart(3, "0")}.webp`);

        const settle = () => {
          if (cancelled) return resolve();
          framesRef.current[index] = image;
          decoded += 1;
          setProgress(decoded / count);
          resolve();
        };

        if (typeof image.decode === "function") {
          image.decode().then(settle, settle);
        } else {
          image.onload = settle;
          image.onerror = () => resolve();
        }
      });

    const run = async () => {
      for (const stride of PASSES) {
        const batch: Promise<void>[] = [];
        for (let index = 0; index < count; index += stride) {
          if (seen.has(index)) continue;
          seen.add(index);
          batch.push(load(index));
        }

        await Promise.all(batch);
        if (cancelled) return;
        setReady(true);
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [dir, count, enabled]);

  return { frames: framesRef.current, progress, ready };
}

/** Walks outward from `index` to the nearest frame that has actually decoded. */
export function nearestFrame(
  frames: (HTMLImageElement | undefined)[],
  index: number,
): HTMLImageElement | undefined {
  const exact = frames[index];
  if (exact) return exact;

  for (let step = 1; step < frames.length; step += 1) {
    const before = frames[index - step];
    if (before) return before;
    const after = frames[index + step];
    if (after) return after;
  }

  return undefined;
}
