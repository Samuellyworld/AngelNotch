import {
  type MouseEvent as ReactMouseEvent,
  useEffect,
  useRef,
  useState,
} from "react";
import { useLenis } from "lenis/react";

import { Wordmark } from "@/components/icons";
import { usePrefersReducedMotion } from "@/hooks/useMediaQuery";
import { easeOutExpo } from "@/components/SmoothScroll/SmoothScroll";
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
  SectionTransition,
  type SectionTransitionPhase,
  ToggleLine,
  ToggleMark,
  TransitionCore,
  TransitionDevice,
  TransitionIndex,
  TransitionLabel,
  TransitionMeta,
  TransitionProgress,
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

const COVER_DURATION_MS = 620;
const SECTION_SCROLL_DURATION_SECONDS = 0.72;
const REVEAL_DELAY_MS = 140;
const REVEAL_DURATION_MS = 760;

type TransitionState = {
  phase: SectionTransitionPhase;
  index: number;
  label: string;
};

export function QuickNav() {
  const [open, setOpen] = useState(false);
  const [activeHref, setActiveHref] = useState<string>(ITEMS[0].href);
  const [transition, setTransition] = useState<TransitionState>({
    phase: "idle",
    index: 0,
    label: ITEMS[0].label,
  });
  const lenis = useLenis();
  const prefersReducedMotion = usePrefersReducedMotion();
  const rootRef = useRef<HTMLDivElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const transitionActiveRef = useRef(false);
  const timersRef = useRef<number[]>([]);
  const activeIndex = ITEMS.findIndex((item) => item.href === activeHref);

  const schedule = (callback: () => void, delay: number) => {
    const timer = window.setTimeout(() => {
      timersRef.current = timersRef.current.filter((current) => current !== timer);
      callback();
    }, delay);

    timersRef.current.push(timer);
    return timer;
  };

  useEffect(
    () => () => {
      timersRef.current.forEach((timer) => window.clearTimeout(timer));
      timersRef.current = [];
    },
    [],
  );

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

  useEffect(() => {
    let frame: number | null = null;

    const updateActiveSection = () => {
      frame = null;
      if (transitionActiveRef.current) return;

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

  const scrollToSection = (href: string, label: string, index: number) => {
    const target = document.querySelector<HTMLElement>(href);
    if (!target) return;

    const navOffset = href === "#top" ? 0 : window.innerWidth <= 760 ? 72 : 88;
    const destination = Math.max(
      0,
      target.getBoundingClientRect().top + window.scrollY - navOffset,
    );

    if (Math.abs(destination - window.scrollY) < 2) {
      setOpen(false);
      finishAt(target, href);
      return;
    }

    if (prefersReducedMotion) {
      setOpen(false);
      window.scrollTo(0, destination);
      finishAt(target, href);
      return;
    }

    transitionActiveRef.current = true;
    setActiveHref(href);
    setTransition({
      phase: "covering",
      index,
      label,
    });

    schedule(() => {
      setTransition((current) => ({ ...current, phase: "covered" }));

      let completed = false;
      const completeScroll = () => {
        if (completed) return;
        completed = true;

        const settledDestination = Math.max(
          0,
          target.getBoundingClientRect().top + window.scrollY - navOffset,
        );

        if (lenis) {
          lenis.scrollTo(settledDestination, { immediate: true, force: true });
        } else {
          window.scrollTo(0, settledDestination);
        }

        finishAt(target, href);

        schedule(() => {
          setOpen(false);
          setTransition((current) => ({ ...current, phase: "revealing" }));

          schedule(() => {
            setTransition((current) => ({ ...current, phase: "idle" }));
            transitionActiveRef.current = false;
          }, REVEAL_DURATION_MS);
        }, REVEAL_DELAY_MS);
      };

      const fallbackTimer = schedule(
        completeScroll,
        SECTION_SCROLL_DURATION_SECONDS * 1000 + 260,
      );

      if (!lenis) {
        window.clearTimeout(fallbackTimer);
        timersRef.current = timersRef.current.filter((timer) => timer !== fallbackTimer);
        window.scrollTo(0, destination);
        completeScroll();
        return;
      }

      lenis.scrollTo(destination, {
        duration: SECTION_SCROLL_DURATION_SECONDS,
        easing: easeOutExpo,
        lock: true,
        onComplete: () => {
          window.clearTimeout(fallbackTimer);
          timersRef.current = timersRef.current.filter((timer) => timer !== fallbackTimer);
          completeScroll();
        },
      });
    }, COVER_DURATION_MS);
  };

  const onItemClick = (
    event: ReactMouseEvent<HTMLAnchorElement>,
    item: (typeof ITEMS)[number],
    index: number,
  ) => {
    event.preventDefault();
    if (transitionActiveRef.current) return;
    scrollToSection(item.href, item.label, index);
  };

  return (
    <>
      <SectionTransition $phase={transition.phase} aria-hidden="true">
        <TransitionDevice $phase={transition.phase}>
          <TransitionCore $phase={transition.phase}>
            <Wordmark size={96} />
          </TransitionCore>
        </TransitionDevice>
        <TransitionMeta $phase={transition.phase}>
          <TransitionIndex>
            {String(transition.index + 1).padStart(2, "0")} /{" "}
            {String(ITEMS.length).padStart(2, "0")}
          </TransitionIndex>
          <TransitionLabel>{transition.label}</TransitionLabel>
        </TransitionMeta>
        <TransitionProgress $phase={transition.phase} />
      </SectionTransition>

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
                    onClick={(event) => onItemClick(event, item, index)}
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
    </>
  );
}
