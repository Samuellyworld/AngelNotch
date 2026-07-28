import { useEffect, useRef, useState } from "react";

import { Wordmark } from "@/components/icons";
import { Button } from "@/components/ui";
import { DOWNLOAD_NAME, DOWNLOAD_URL, REPO_URL } from "@/lib/site";
import {
  Actions,
  Brand,
  NavBar,
  NavWrap,
  Progress,
  StarIcon,
  StarLabel,
  StarLink,
} from "./Nav.styles";

export function Nav() {
  const [docked, setDocked] = useState(false);
  const progressRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    let raf = 0;

    const update = () => {
      const scrolled = window.scrollY;
      const travel = document.documentElement.scrollHeight - window.innerHeight;
      const ratio = travel > 0 ? Math.min(1, scrolled / travel) : 0;

      if (progressRef.current) {
        progressRef.current.style.transform = `scaleX(${ratio})`;
      }

      setDocked((current) => {
        const next = scrolled > 24;
        return next === current ? current : next;
      });
    };

    const schedule = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(update);
    };

    update();
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule, { passive: true });

    return () => {
      window.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", schedule);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <NavWrap>
      <NavBar $docked={docked} aria-label="Primary">
        <Brand href="#top">
          <Wordmark size={24} animated />
          AngelNotch
        </Brand>

        <Actions>
          <StarLink
            href={REPO_URL}
            target="_blank"
            rel="noreferrer"
            aria-label="Star AngelNotch on GitHub"
          >
            <StarIcon name="star" size={15} />
            <StarLabel>Star</StarLabel>
          </StarLink>

          <Button href={DOWNLOAD_URL} download={DOWNLOAD_NAME} size="small" icon="download">
            Download
          </Button>
        </Actions>

        <Progress ref={progressRef} aria-hidden="true" />
      </NavBar>
    </NavWrap>
  );
}
