import { Icon } from "@/components/icons";
import { Section } from "@/components/ui";
import { PERMISSIONS, PRIVACY_CLAIMS } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  Claim,
  Claims,
  Permission,
  PermissionIcon,
  PermissionName,
  PermissionPurpose,
  Permissions,
  PrivacyCard,
  PrivacyGrid,
  PrivacyKicker,
  PrivacyLede,
  PrivacyNote,
  PrivacyTitle,
} from "./Privacy.styles";

export function Privacy() {
  return (
    <Section id="privacy" index="05" label="Privacy">
      <PrivacyCard>
        <PrivacyGrid>
          <div>
            <PrivacyTitle>
              Your information stays <Serif>on your Mac.</Serif>
            </PrivacyTitle>

            <PrivacyLede>
              AngelNotch is local-first. Clipboard history, saved file references, focus state and
              integration data never leave the machine they were created on. If you choose to
              download from this website, your email is stored in Brevo for release notes and
              product updates only.
            </PrivacyLede>

            <Claims>
              {PRIVACY_CLAIMS.map((claim) => (
                <Claim key={claim}>
                  <Icon name="shield" size={14} />
                  {claim}
                </Claim>
              ))}
            </Claims>
          </div>

          <div>
            <PrivacyKicker>Asked for only when used</PrivacyKicker>

            <Permissions>
              {PERMISSIONS.map((permission) => (
                <Permission key={permission.name}>
                  <PermissionIcon name={permission.icon} size={18} />
                  <div>
                    <PermissionName>{permission.name}</PermissionName>
                    <PermissionPurpose>{permission.purpose}</PermissionPurpose>
                  </div>
                </Permission>
              ))}
            </Permissions>

            <PrivacyNote>
              AngelNotch does not record, store, transcribe or transmit microphone or camera
              content. During a call it may sample local microphone amplitude only to draw the
              compact waveform.
            </PrivacyNote>
          </div>
        </PrivacyGrid>
      </PrivacyCard>
    </Section>
  );
}
