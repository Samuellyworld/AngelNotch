import { Reveal } from "@/components/ui";
import { Serif } from "@/styles/GlobalStyles";
import {
  IntroBody,
  IntroGrid,
  IntroHeadline,
  IntroSection,
  Pillar,
  PillarBody,
  PillarIndex,
  Pillars,
  PillarTitle,
} from "./Intro.styles";

const PILLARS = [
  {
    index: "i",
    title: "Everything within reach",
    body: "The controls and readouts you touch all day live at the top of the screen, a flick of the pointer away.",
  },
  {
    index: "ii",
    title: "Designed for focus",
    body: "Several small tools share one surface, so a quick check never turns into a detour through three apps.",
  },
  {
    index: "iii",
    title: "Private by design",
    body: "App data stays on the Mac. No in-app account, analytics, advertising or tracking SDKs.",
  },
];

export function Intro() {
  return (
    <IntroSection id="intro" index="01" label="More than a notch">
      <IntroGrid>
        <Reveal>
          <IntroHeadline>
            The black bar
            <br />
            starts <Serif>working.</Serif>
          </IntroHeadline>
        </Reveal>

        <IntroBody delay={90}>
          <p>
            AngelNotch puts the tools you use through the day in one convenient place. Control your
            music, find something you copied earlier, keep important files nearby, start a focus
            session, check your next meeting, or adjust your Mac.
          </p>
          <p>All of it without breaking your flow.</p>
        </IntroBody>
      </IntroGrid>

      <Pillars>
        {PILLARS.map((pillar, position) => (
          <Pillar key={pillar.index} delay={position * 90}>
            <PillarIndex>{pillar.index}</PillarIndex>
            <PillarTitle>{pillar.title}</PillarTitle>
            <PillarBody>{pillar.body}</PillarBody>
          </Pillar>
        ))}
      </Pillars>
    </IntroSection>
  );
}
