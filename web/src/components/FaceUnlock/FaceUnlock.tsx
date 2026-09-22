import { useEffect, useRef, useState } from "react";

import { Icon } from "@/components/icons";
import { Reveal, Section } from "@/components/ui";
import { Serif } from "@/styles/GlobalStyles";
import {
  DemoCard,
  DemoCopy,
  DemoGrid,
  DemoStage,
  FaceFrame,
  FaceSilhouette,
  LockGlyph,
  MacBody,
  MacScreen,
  Notch,
  ScanBeam,
  SecurityNote,
  StatusStack,
  Step,
  Steps,
} from "./FaceUnlock.styles";

export function FaceUnlock() {
  const [run, setRun] = useState(0);
  const [playing, setPlaying] = useState(false);
  const demoRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const demo = demoRef.current;
    if (!demo) return;

    if (!("IntersectionObserver" in window)) {
      setPlaying(true);
      setRun((value) => value + 1);
      return;
    }

    let wasVisible = false;
    const observer = new IntersectionObserver(
      ([entry]) => {
        const visible = Boolean(entry?.isIntersecting && entry.intersectionRatio >= 0.35);
        if (visible && !wasVisible) {
          setRun((value) => value + 1);
        }
        wasVisible = visible;
        setPlaying(visible);
      },
      { threshold: [0, 0.35, 0.7], rootMargin: "0px 0px -8% 0px" },
    );

    observer.observe(demo);
    return () => observer.disconnect();
  }, []);

  return (
    <Section
      id="face-unlock"
      index="03"
      label="Face Unlock"
      title={
        <>
          Look at your Mac. <Serif>You&apos;re in.</Serif>
        </>
      }
      lede="AngelNotch can recognize you when your Mac locks or wakes, run independent liveness checks, then enter your encrypted password locally."
    >
      <DemoGrid>
        <Reveal>
          <DemoCard ref={demoRef}>
            <DemoStage
              key={run}
              $playing={playing}
              aria-label="Animation demonstrating AngelNotch Face Unlock"
            >
              <MacBody>
                <MacScreen>
                  <Notch>
                    <span />
                  </Notch>
                  <FaceFrame>
                    <FaceSilhouette>
                      <span />
                    </FaceSilhouette>
                    <ScanBeam />
                  </FaceFrame>
                  <LockGlyph>
                    <Icon name="shield" size={23} />
                  </LockGlyph>
                  <StatusStack>
                    <span>Mac locked</span>
                    <span>Checking face + liveness</span>
                    <span>Welcome back</span>
                  </StatusStack>
                </MacScreen>
              </MacBody>
            </DemoStage>
          </DemoCard>
        </Reveal>

        <Reveal delay={100}>
          <DemoCopy>
            <Steps>
              <Step>
                <span>01</span>
                <div>
                  <strong>Wakes with the lock screen</strong>
                  <p>The camera only starts for an enabled Face Unlock session.</p>
                </div>
              </Step>
              <Step>
                <span>02</span>
                <div>
                  <strong>Matches face and motion</strong>
                  <p>Recognition and multi-frame liveness checks must both succeed.</p>
                </div>
              </Step>
              <Step>
                <span>03</span>
                <div>
                  <strong>Unlocks locally</strong>
                  <p>Your password and face template stay encrypted on this Mac.</p>
                </div>
              </Step>
            </Steps>
            <SecurityNote>
              <Icon name="shield" size={20} />
              <p>
                Mac cameras do not have Face ID depth sensors. Face Unlock is a convenience
                feature and may not reject a convincing video.
              </p>
            </SecurityNote>
          </DemoCopy>
        </Reveal>
      </DemoGrid>
    </Section>
  );
}
