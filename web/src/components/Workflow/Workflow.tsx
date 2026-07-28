import { Wordmark } from "@/components/icons";
import { Keys, Reveal } from "@/components/ui";
import { SHORTCUTS } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  NotchCamera,
  NotchCaption,
  NotchChevron,
  NotchPill,
  NotchPreview,
  NotchStrip,
  Shortcut,
  ShortcutLabel,
  Shortcuts,
  WorkflowGrid,
  WorkflowSection,
} from "./Workflow.styles";

export function Workflow() {
  return (
    <WorkflowSection
      id="workflow"
      index="04"
      label="In use"
      title={
        <>
          Useful when you need it. <Serif>Invisible when you don’t.</Serif>
        </>
      }
      lede="AngelNotch runs quietly as a menu-bar app. Open it from the menu bar, reach for the notch itself, or use a global shortcut."
    >
      <WorkflowGrid>
        <Reveal>
          <Shortcuts>
            {SHORTCUTS.map((shortcut) => (
              <Shortcut key={shortcut.label}>
                <ShortcutLabel>{shortcut.label}</ShortcutLabel>
                <Keys keys={shortcut.keys} />
              </Shortcut>
            ))}
          </Shortcuts>
        </Reveal>

        <Reveal delay={110}>
          <NotchStrip>
            <NotchPreview
              role="img"
              aria-label="The collapsed AngelNotch pill resting in the MacBook notch, showing the animated loop mark and a chevron."
            >
              <NotchCamera aria-hidden="true" />
              <NotchPill>
                <Wordmark size={25} />
                <NotchChevron name="chevron" size={18} />
              </NotchPill>
            </NotchPreview>
            <NotchCaption>Collapsed, this is the whole interface.</NotchCaption>
          </NotchStrip>
        </Reveal>
      </WorkflowGrid>
    </WorkflowSection>
  );
}
