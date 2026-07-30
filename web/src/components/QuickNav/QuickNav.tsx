import {
  type MouseEvent as ReactMouseEvent,
  useEffect,
  useRef,
  useState,
} from "react";

import { usePrefersReducedMotion } from "@/hooks/useMediaQuery";
import {
  QuickNavArrow,
  QuickNavContent,
  QuickNavCount,
  QuickNavEyebrow,
  QuickNavHeading,
  QuickNavIndex,
  QuickNavLink,
  QuickNavLinks,
  QuickNavPanel,
  QuickNavRoot,
  QuickNavToggle,
  ToggleLine,
  ToggleMark,
} from "./QuickNav.styles";

const ITEMS = [
  { href: "#top", label: "Home" },
  { href: "#intro", label: "Overview" },
  { href: "#features", label: "Features" },
  { href: "#gallery", label: "Gallery" },
  { href: "#workflow", label: "Workflow" },
  { href: "#privacy", label: "Privacy" },
  { href: "#requirements", label: "Requirements" },
  { href: "#faq", label: "FAQ" },
] as const;

const SECTION_SCROLL_DURATION = 2000;

/* Matches the reference site's inertial feel: an immediate, controlled move
   followed by a long, soft settle instead of an accelerate-then-brake curve. */
const easeOutExpo = (progress: number) => {
  if (progress >= 1) return 1;
  const strength = 6;
  return (1 - Math.pow(2, -strength * progress)) / (1 - Math.pow(2, -strength));
};

export function QuickNav() {
  const [open, setOpen] = useState(false);
  const [activeHref, setActiveHref] = useState<string>(ITEMS[0].href);
  const prefersReducedMotion = usePrefersReducedMotion();
  const rootRef = useRef<HTMLDivElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const scrollFrameRef = useRef<number | null>(null);
  const scrollDelayRef = useRef<number | null>(null);
  const activeIndex = ITEMS.findIndex((item) => item.href === activeHref);

  const cancelPendingScroll = () => {
    if (scrollFrameRef.current !== null) {
      window.cancelAnimationFrame(scrollFrameRef.current);
      scrollFrameRef.current = null;
    }

    if (scrollDelayRef.current !== null) {
      window.clearTimeout(scrollDelayRef.current);
      scrollDelayRef.current = null;
    }
  };

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      setOpen(false);
      toggleRef.current?.focus();
    };

    document.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);

    return () => {
      document.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  useEffect(
    () => {
      const interruptScroll = () => cancelPendingScroll();
      window.addEventListener("wheel", interruptScroll, { passive: true });
      window.addEventListener("touchstart", interruptScroll, { passive: true });

      return () => {
        window.removeEventListener("wheel", interruptScroll);
        window.removeEventListener("touchstart", interruptScroll);
        cancelPendingScroll();
      };
    },
    [],
  );

  useEffect(() => {
    let frame: number | null = null;

    const updateActiveSection = () => {
      frame = null;
      const marker = window.innerHeight * 0.36;
      let currentHref: string = ITEMS[0].href;

      for (const item of ITEMS) {
        const section = document.querySelector<HTMLElement>(item.href);
        if (!section || section.getBoundingClientRect().top > marker) break;
        currentHref = item.href;
      }

      setActiveHref((current) => (current === currentHref ? current : currentHref));
    };

    const scheduleUpdate = () => {
      if (frame !== null) return;
      frame = window.requestAnimationFrame(updateActiveSection);
    };

    scheduleUpdate();
    window.addEventListener("scroll", scheduleUpdate, { passive: true });
    window.addEventListener("resize", scheduleUpdate);
    window.addEventListener("hashchange", scheduleUpdate);

    return () => {
      window.removeEventListener("scroll", scheduleUpdate);
      window.removeEventListener("resize", scheduleUpdate);
      window.removeEventListener("hashchange", scheduleUpdate);
      if (frame !== null) window.cancelAnimationFrame(frame);
    };
  }, []);

  const finishAt = (target: HTMLElement, href: string) => {
    window.history.pushState(null, "", href);
    setActiveHref(href);

    const hadTabIndex = target.hasAttribute("tabindex");
    if (!hadTabIndex) target.setAttribute("tabindex", "-1");
    target.focus({ preventScroll: true });

    if (!hadTabIndex) {
      target.addEventListener("blur", () => target.removeAttribute("tabindex"), { once: true });
    }
  };

  const scrollToSection = (href: string) => {
    const target = document.querySelector<HTMLElement>(href);
    if (!target) return;

    cancelPendingScroll();

    const start = window.scrollY;
    const navOffset = href === "#top" ? 0 : window.innerWidth <= 760 ? 72 : 88;
    const destination = Math.max(0, target.getBoundingClientRect().top + start - navOffset);
    const distance = destination - start;

    if (prefersReducedMotion || Math.abs(distance) < 2) {
      window.scrollTo(0, destination);
      finishAt(target, href);
      return;
    }

    const startedAt = performance.now();

    const step = (now: number) => {
      const progress = Math.min(1, (now - startedAt) / SECTION_SCROLL_DURATION);
      window.scrollTo(0, start + distance * easeOutExpo(progress));

      if (progress < 1) {
        scrollFrameRef.current = window.requestAnimationFrame(step);
        return;
      }

      scrollFrameRef.current = null;
      finishAt(target, href);
    };

    scrollFrameRef.current = window.requestAnimationFrame(step);
  };

  const onItemClick = (event: ReactMouseEvent<HTMLAnchorElement>, href: string) => {
    event.preventDefault();
    cancelPendingScroll();
    setActiveHref(href);
    setOpen(false);

    const delay = prefersReducedMotion ? 0 : 60;
    scrollDelayRef.current = window.setTimeout(() => {
      scrollDelayRef.current = null;
      scrollToSection(href);
    }, delay);
  };

  return (
    <QuickNavRoot ref={rootRef}>
      <QuickNavPanel id="quick-nav-panel" $open={open} aria-hidden={!open}>
        <QuickNavContent $open={open}>
          <QuickNavHeading>
            <QuickNavEyebrow>Site index</QuickNavEyebrow>
            <QuickNavCount>
              {String(activeIndex + 1).padStart(2, "0")} /{" "}
              {String(ITEMS.length).padStart(2, "0")}
            </QuickNavCount>
          </QuickNavHeading>

          <QuickNavLinks aria-label="Page sections">
            {ITEMS.map((item, index) => {
              const active = item.href === activeHref;

              return (
                <QuickNavLink
                  key={item.href}
                  href={item.href}
                  $active={active}
                  $open={open}
                  $delay={120 + index * 24}
                  aria-current={active ? "location" : undefined}
                  tabIndex={open ? 0 : -1}
                  onClick={(event) => onItemClick(event, item.href)}
                >
                  <QuickNavIndex>{String(index + 1).padStart(2, "0")}</QuickNavIndex>
                  <span>{item.label}</span>
                  <QuickNavArrow name="arrow" size={15} />
                </QuickNavLink>
              );
            })}
          </QuickNavLinks>
        </QuickNavContent>
      </QuickNavPanel>

      <QuickNavToggle
        ref={toggleRef}
        type="button"
        $open={open}
        aria-label={open ? "Close section menu" : "Open section menu"}
        aria-controls="quick-nav-panel"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
      >
        <ToggleMark aria-hidden="true">
          <ToggleLine $open={open} $position="top" />
          <ToggleLine $open={open} $position="middle" />
          <ToggleLine $open={open} $position="bottom" />
        </ToggleMark>
      </QuickNavToggle>
    </QuickNavRoot>
  );
}
