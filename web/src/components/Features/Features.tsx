import { Icon } from "@/components/icons";
import { asset } from "@/lib/asset";
import { Section } from "@/components/ui";
import { FEATURES, type Feature } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  Copy,
  FeatureBlurb,
  FeatureIndex,
  FeatureRowContainer,
  FeatureTitle,
  Glyph,
  MarkBlurb,
  MarkCard,
  MarkCards,
  MarkIcon,
  MarkTitle,
  Media,
  Meta,
  Rows,
  Shot,
  VisualFrame,
} from "./Features.styles";

function FeatureRow({ feature, position }: { feature: Feature; position: number }) {
  return (
    <FeatureRowContainer $tint={feature.tint}>
      <Copy delay={40}>
        <Meta>
          <Glyph>
            <Icon name={feature.icon} size={20} />
          </Glyph>
          <FeatureIndex>{feature.index}</FeatureIndex>
        </Meta>
        <FeatureTitle>{feature.title}</FeatureTitle>
        <FeatureBlurb>{feature.blurb}</FeatureBlurb>
      </Copy>

      <Media delay={120}>
        <VisualFrame $plate={feature.kind === "mockup"}>
          <Shot
            $capture={feature.kind === "capture"}
            src={asset(feature.shot ?? "")}
            alt={feature.alt ?? ""}
            loading={position < 2 ? "eager" : "lazy"}
            decoding="async"
          />
        </VisualFrame>
      </Media>
    </FeatureRowContainer>
  );
}

export function Features() {
  const illustrated = FEATURES.filter((feature) => feature.kind !== "mark");
  const listed = FEATURES.filter((feature) => feature.kind === "mark");

  return (
    <Section
      id="features"
      index="02"
      label="Features"
      title={
        <>
          Nine small tools, <Serif>one small space.</Serif>
        </>
      }
      lede="Each one earns its place by saving a trip to another window. None of them needs an account, a subscription or a connection."
    >
      <Rows>
        {illustrated.map((feature, position) => (
          <FeatureRow key={feature.id} feature={feature} position={position} />
        ))}
      </Rows>

      <MarkCards>
        {listed.map((feature, position) => (
          <MarkCard
            key={feature.id}
            delay={position * 70}
            $tint={feature.tint}
            $motionDelay={position * -480}
          >
            <MarkIcon>
              <Icon name={feature.icon} size={24} />
            </MarkIcon>
            <MarkTitle>{feature.title}</MarkTitle>
            <MarkBlurb>{feature.blurb}</MarkBlurb>
          </MarkCard>
        ))}
      </MarkCards>
    </Section>
  );
}
