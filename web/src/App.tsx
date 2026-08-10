import { Extension } from "@/components/Extension/Extension";
import { Cursor } from "@/components/Cursor/Cursor";
import { DownloadGate } from "@/components/DownloadGate/DownloadGate";
import { Faq } from "@/components/Faq/Faq";
import { Features } from "@/components/Features/Features";
import { FinalCta } from "@/components/FinalCta/FinalCta";
import { Footer } from "@/components/Footer/Footer";
import { Gallery } from "@/components/Gallery/Gallery";
import { Hero } from "@/components/Hero/Hero";
import { Intro } from "@/components/Intro/Intro";
import { Marquee } from "@/components/Marquee/Marquee";
import { Nav } from "@/components/Nav/Nav";
import { Privacy } from "@/components/Privacy/Privacy";
import { QuickNav } from "@/components/QuickNav/QuickNav";
import { Requirements } from "@/components/Requirements/Requirements";
import { SmoothScroll } from "@/components/SmoothScroll/SmoothScroll";
import { Workflow } from "@/components/Workflow/Workflow";
import { Grain, SkipLink } from "@/styles/GlobalStyles";

export function App() {
  return (
    <>
      <SmoothScroll />

      <SkipLink href="#intro">
        Skip to content
      </SkipLink>

      <Nav />
      <QuickNav />

      <main>
        <Hero />
        <Intro />
        <Marquee />
        <Features />
        <Gallery />
        <Workflow />
        <Privacy />
        <Extension />
        <Requirements />
        <Faq />
        <FinalCta />
      </main>

      <Footer />
      <Cursor />
      <DownloadGate />
      <Grain aria-hidden="true" />
    </>
  );
}
