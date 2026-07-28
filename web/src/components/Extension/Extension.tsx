import { Icon } from "@/components/icons";
import { Button } from "@/components/ui";
import { EXTENSION_SETUP_URL } from "@/lib/site";
import { Shell } from "@/styles/GlobalStyles";
import {
  ExtensionBand,
  ExtensionBody,
  ExtensionCard,
  ExtensionIcon,
  ExtensionTitle,
  Optional,
} from "./Extension.styles";

export function Extension() {
  return (
    <ExtensionBand>
      <Shell>
        <ExtensionCard>
          <ExtensionIcon>
            <Icon name="chrome" size={22} />
          </ExtensionIcon>

          <div>
            <ExtensionTitle>
              Even better with Chrome
              <Optional>Optional</Optional>
            </ExtensionTitle>
            <ExtensionBody>
              The AngelNotch Chrome extension adds YouTube playback information and Chrome download
              progress. Every other feature works without it.
            </ExtensionBody>
          </div>

          <Button
            href={EXTENSION_SETUP_URL}
            target="_blank"
            rel="noreferrer"
            variant="secondary"
            size="small"
            trailing="arrow"
          >
            Setup guide
          </Button>
        </ExtensionCard>
      </Shell>
    </ExtensionBand>
  );
}
