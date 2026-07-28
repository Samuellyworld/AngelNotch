import { Button } from "@/components/ui";
import {
  DOWNLOAD_NAME,
  DOWNLOAD_SIZE,
  DOWNLOAD_URL,
  MIN_MACOS,
  RELEASES_URL,
  REPO_URL,
} from "@/lib/site";
import { Serif, Shell } from "@/styles/GlobalStyles";
import {
  CtaBody,
  CtaButtons,
  CtaCard,
  CtaFine,
  CtaTitle,
  FinalBand,
} from "./FinalCta.styles";

export function FinalCta() {
  return (
    <FinalBand>
      <Shell>
        <CtaCard>
          <CtaTitle>
            Make your notch <Serif>useful.</Serif>
          </CtaTitle>

          <CtaBody>
            Keep your music, files, clipboard, meetings, focus tools and Mac controls one glance
            away.
          </CtaBody>

          <CtaButtons>
            <Button href={DOWNLOAD_URL} download={DOWNLOAD_NAME} icon="download" meta={DOWNLOAD_SIZE}>
              Download AngelNotch
            </Button>
            <Button
              href={REPO_URL}
              target="_blank"
              rel="noreferrer"
              variant="secondary"
              icon="github"
            >
              View source code
            </Button>
          </CtaButtons>

          <CtaFine>
            {MIN_MACOS} or newer ·{" "}
            <a href={RELEASES_URL} target="_blank" rel="noreferrer">
              all releases
            </a>
          </CtaFine>
        </CtaCard>
      </Shell>
    </FinalBand>
  );
}
