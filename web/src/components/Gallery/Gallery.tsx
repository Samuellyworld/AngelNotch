import { useEffect, useRef } from "react";

import { useIsCompact, usePrefersReducedMotion } from "@/hooks/useMediaQuery";
import { asset } from "@/lib/asset";
import { GALLERY } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  Caption,
  CardTitle,
  Counter,
  Description,
  GalleryCard,
  GallerySection,
  ReelHeader,
  Scene,
  ScrollHint,
  Shot,
  Sticky,
  SurfaceKind,
  Track,
  TrackViewport,
  Visual,
} from "./Gallery.styles";

export function Gallery() {
  const sceneRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const compact = useIsCompact();
  const reducedMotion = usePrefersReducedMotion();
  const staticLayout = compact || reducedMotion;

  useEffect(() => {
    const scene = sceneRef.current;
    const track = trackRef.current;
    if (!scene || !track || staticLayout) return;

    let frame = 0;

    const update = () => {
      frame = 0;

      const rect = scene.getBoundingClientRect();
      const scrollDistance = Math.max(scene.offsetHeight - window.innerHeight, 1);
      const progress = Math.min(Math.max(-rect.top / scrollDistance, 0), 1);
      const travel = Math.max(track.scrollWidth - window.innerWidth, 0);

      track.style.transform = `translate3d(${-travel * progress}px, 0, 0)`;
    };

    const requestUpdate = () => {
      if (!frame) frame = window.requestAnimationFrame(update);
    };

    const resizeObserver = new ResizeObserver(requestUpdate);
    resizeObserver.observe(scene);
    resizeObserver.observe(track);
    window.addEventListener("scroll", requestUpdate, { passive: true });
    window.addEventListener("resize", requestUpdate);
    update();

    return () => {
      resizeObserver.disconnect();
      window.removeEventListener("scroll", requestUpdate);
      window.removeEventListener("resize", requestUpdate);
      if (frame) window.cancelAnimationFrame(frame);
      track.style.transform = "";
    };
  }, [staticLayout]);

  return (
    <GallerySection
      id="gallery"
      index="03"
      label="Gallery"
      title={
        <>
          The whole interface, <Serif>in plain sight.</Serif>
        </>
      }
      lede="Five working surfaces from the app, arranged as one continuous gallery."
    >
      <Scene ref={sceneRef} $static={staticLayout}>
        <Sticky $static={staticLayout}>
          <ReelHeader $static={staticLayout}>
            <span>Inside AngelNotch</span>
            <ScrollHint>
              {staticLayout ? "Swipe" : "Scroll"} <span aria-hidden="true">→</span>
            </ScrollHint>
          </ReelHeader>

          <TrackViewport $static={staticLayout}>
            <Track ref={trackRef} $static={staticLayout}>
              {GALLERY.map((view, index) => (
                <GalleryCard key={view.id} $static={staticLayout}>
                  <Visual>
                    <Counter>{String(index + 1).padStart(2, "0")}</Counter>
                    <Shot
                      src={asset(view.shot)}
                      alt={view.alt}
                      loading={index < 2 ? "eager" : "lazy"}
                      decoding="async"
                    />
                  </Visual>

                  <Caption>
                    <div>
                      <SurfaceKind>
                        {view.real ? "Product surface" : "Prototype surface"}
                      </SurfaceKind>
                      <CardTitle>{view.tab}</CardTitle>
                    </div>
                    <Description>{view.caption}</Description>
                  </Caption>
                </GalleryCard>
              ))}
            </Track>
          </TrackViewport>
        </Sticky>
      </Scene>
    </GallerySection>
  );
}
