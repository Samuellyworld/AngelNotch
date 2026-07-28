import { useEffect, useRef, useState } from "react";

type Options = {
  /** Fraction of the element that must be visible before it counts. */
  threshold?: number;
  /** Shifts the trigger line up from the viewport bottom. */
  rootMargin?: string;
};

/** One-shot visibility flag. Elements animate in once and then stay put, which
 *  keeps long pages calm instead of flickering on every scroll direction. */
export function useReveal<T extends HTMLElement>({
  threshold = 0.18,
  rootMargin = "0px 0px -8% 0px",
}: Options = {}) {
  const ref = useRef<T>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node || shown) return;

    if (!("IntersectionObserver" in window)) {
      setShown(true);
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setShown(true);
            observer.disconnect();
          }
        }
      },
      { threshold, rootMargin },
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [shown, threshold, rootMargin]);

  return { ref, shown };
}
