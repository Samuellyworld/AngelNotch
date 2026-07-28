import { useEffect, useRef } from "react";

import { CursorNotch, CursorPointer, CursorRoot } from "./Cursor.styles";

const INTERACTIVE_SELECTOR = "a, button, [role='button'], summary, [data-cursor='interactive']";

export function Cursor() {
  const cursorRef = useRef<HTMLDivElement>(null);
  const pointerRef = useRef<HTMLSpanElement>(null);
  const notchRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (!finePointer.matches || reducedMotion.matches) return;

    const cursor = cursorRef.current;
    const pointer = pointerRef.current;
    const notch = notchRef.current;
    if (!cursor || !pointer || !notch) return;

    let targetX = -80;
    let targetY = -80;
    let notchX = targetX;
    let notchY = targetY;
    let frame = 0;

    document.documentElement.classList.add("custom-cursor-active");

    const render = () => {
      notchX += (targetX - notchX) * 0.2;
      notchY += (targetY - notchY) * 0.2;

      pointer.style.transform = `translate3d(${targetX}px, ${targetY}px, 0)`;
      notch.style.transform = `translate3d(${notchX}px, ${notchY}px, 0) translate(-50%, -50%)`;
      frame = window.requestAnimationFrame(render);
    };

    const onPointerMove = (event: PointerEvent) => {
      targetX = event.clientX;
      targetY = event.clientY;
      cursor.dataset.visible = "true";

      const source = event.target;
      const interactive =
        source instanceof Element ? source.closest<HTMLElement>(INTERACTIVE_SELECTOR) : null;
      cursor.dataset.interactive = interactive ? "true" : "false";

      if (interactive) {
        const rect = interactive.getBoundingClientRect();
        interactive.style.setProperty("--hover-x", `${event.clientX - rect.left}px`);
        interactive.style.setProperty("--hover-y", `${event.clientY - rect.top}px`);
      }
    };

    const onPointerLeave = () => {
      cursor.dataset.visible = "false";
      cursor.dataset.interactive = "false";
    };

    const onPointerDown = () => {
      cursor.dataset.pressed = "true";
    };

    const onPointerUp = () => {
      cursor.dataset.pressed = "false";
    };

    frame = window.requestAnimationFrame(render);
    window.addEventListener("pointermove", onPointerMove, { passive: true });
    document.documentElement.addEventListener("mouseleave", onPointerLeave);
    window.addEventListener("pointerdown", onPointerDown, { passive: true });
    window.addEventListener("pointerup", onPointerUp, { passive: true });

    return () => {
      document.documentElement.classList.remove("custom-cursor-active");
      window.removeEventListener("pointermove", onPointerMove);
      document.documentElement.removeEventListener("mouseleave", onPointerLeave);
      window.removeEventListener("pointerdown", onPointerDown);
      window.removeEventListener("pointerup", onPointerUp);
      window.cancelAnimationFrame(frame);
    };
  }, []);

  return (
    <CursorRoot
      ref={cursorRef}
      data-visible="false"
      data-interactive="false"
      data-pressed="false"
      aria-hidden="true"
    >
      <CursorNotch ref={notchRef} />
      <CursorPointer ref={pointerRef} />
    </CursorRoot>
  );
}
