import { Hero } from "@/components/Hero/Hero";
import { Grain, SkipLink } from "@/styles/GlobalStyles";

export function App() {
  return (
    <>
      <SkipLink href="#top">Skip to content</SkipLink>

      <main>
        <Hero />
      </main>

      <Grain aria-hidden="true" />
    </>
  );
}
