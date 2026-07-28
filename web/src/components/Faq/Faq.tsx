import { useState } from "react";

import { Reveal, Section } from "@/components/ui";
import { FAQS } from "@/lib/content";
import { Serif } from "@/styles/GlobalStyles";
import {
  FaqAnswer,
  FaqItemRoot,
  FaqList,
  FaqMark,
  FaqMarkWrap,
  FaqPanel,
  FaqPanelInner,
  FaqSummary,
} from "./Faq.styles";

function FaqItem({
  faq,
  position,
}: {
  faq: (typeof FAQS)[number];
  position: number;
}) {
  const [open, setOpen] = useState(false);
  const questionId = `faq-question-${position}`;
  const answerId = `faq-answer-${position}`;

  return (
    <FaqItemRoot>
      <FaqSummary
        id={questionId}
        $open={open}
        type="button"
        aria-expanded={open}
        aria-controls={answerId}
        onClick={() => setOpen((current) => !current)}
      >
        <span>{faq.q}</span>
        <FaqMarkWrap $open={open} aria-hidden="true">
          <FaqMark name="plus" size={17} $open={open} />
        </FaqMarkWrap>
      </FaqSummary>

      <FaqPanel
        id={answerId}
        $open={open}
        role="region"
        aria-labelledby={questionId}
        aria-hidden={!open}
      >
        <FaqPanelInner>
          <FaqAnswer>{faq.a}</FaqAnswer>
        </FaqPanelInner>
      </FaqPanel>
    </FaqItemRoot>
  );
}

export function Faq() {
  return (
    <Section
      id="faq"
      index="07"
      label="FAQ"
      title={
        <>
          The questions <Serif>worth asking.</Serif>
        </>
      }
    >
      <FaqList>
        {FAQS.map((faq, position) => (
          <Reveal key={faq.q} delay={Math.min(position * 50, 250)}>
            <FaqItem faq={faq} position={position} />
          </Reveal>
        ))}
      </FaqList>
    </Section>
  );
}
