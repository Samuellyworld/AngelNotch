import { styled } from "styled-components";

export const FooterRoot = styled.footer`
  padding-block: clamp(3rem, 2rem + 3vw, 5rem) clamp(2rem, 1.5rem + 2vw, 3rem);
  border-top: 1px solid var(--outline);
`;

export const FooterTop = styled.div`
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 2rem;
  padding-bottom: 2.5rem;

  @media (max-width: 600px) {
    flex-direction: column;
  }
`;

export const FooterBrand = styled.div`
  display: flex;
  max-width: 30ch;
  flex-direction: column;
  gap: 0.8rem;
`;

export const FooterName = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  font-size: 1.05rem;
  font-weight: 500;
  letter-spacing: -0.03em;
`;

export const FooterTag = styled.p`
  color: var(--ink-tertiary);
  font-size: 0.88rem;
  line-height: 1.6;
`;

export const FooterColumns = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: clamp(2rem, 1rem + 4vw, 5rem);

  @media (max-width: 600px) {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    width: 100%;
    gap: 2rem 1.5rem;
  }
`;

export const FooterColumn = styled.nav`
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
`;

export const FooterHeading = styled.p`
  color: var(--ink-faint);
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
`;

export const FooterLink = styled.a`
  color: var(--ink-secondary);
  font-size: 0.92rem;
  transition: color var(--dur-fast) var(--ease-out);

  &:hover {
    color: var(--accent);
  }
`;

export const FooterBottom = styled.div`
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding-top: 1.6rem;
  border-top: 1px solid var(--outline);
  color: var(--ink-faint);
  font-size: 0.8rem;

  @media (max-width: 600px) {
    align-items: flex-start;
    flex-direction: column;
  }
`;

export const Credit = styled.span`
  color: rgba(243, 237, 227, 0.62);
  transition: color var(--dur-fast) var(--ease-out);

  a {
    border-bottom: 1px solid transparent;
    color: rgba(243, 237, 227, 0.82);
    transition:
      color var(--dur-fast) var(--ease-out),
      border-color var(--dur-fast) var(--ease-out);
  }

  a:hover {
    border-bottom-color: rgba(232, 133, 97, 0.4);
    color: var(--accent);
  }
`;
