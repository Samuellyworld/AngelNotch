import { Icon } from "@/components/icons";
import { MarqueeItem, MarqueeRoot, MarqueeTrack } from "./Marquee.styles";

const ITEMS = [
  "Media controls",
  "Clipboard history",
  "File shelf",
  "Focus timer",
  "Calendar",
  "System controls",
  "Live indicators",
  "Live activities",
  "Contextual actions",
];

function Track({ hidden }: { hidden?: boolean }) {
  return (
    <MarqueeTrack aria-hidden={hidden ? "true" : undefined}>
      {ITEMS.map((item) => (
        <MarqueeItem key={item}>
          <Icon name="notch" size={13} />
          {item}
        </MarqueeItem>
      ))}
    </MarqueeTrack>
  );
}

/** A single continuous strip. The second copy makes the loop seamless and is
 *  hidden from assistive technology so the list is only read once. */
export function Marquee() {
  return (
    <MarqueeRoot>
      <Track />
      <Track hidden />
    </MarqueeRoot>
  );
}
