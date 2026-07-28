import { Section } from "@/components/ui";
import { REQUIREMENTS } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  RequirementCard,
  RequirementDetail,
  RequirementIcon,
  RequirementLabel,
  RequirementsGrid,
} from "./Requirements.styles";

export function Requirements() {
  return (
    <Section
      id="requirements"
      index="06"
      label="Requirements"
      title={
        <>
          Short list, <Serif>no surprises.</Serif>
        </>
      }
    >
      <RequirementsGrid>
        {REQUIREMENTS.map((requirement, position) => (
          <RequirementCard key={requirement.label} delay={position * 80}>
            <RequirementIcon name={requirement.icon} size={22} />
            <RequirementLabel>{requirement.label}</RequirementLabel>
            <RequirementDetail>{requirement.detail}</RequirementDetail>
          </RequirementCard>
        ))}
      </RequirementsGrid>
    </Section>
  );
}
