import { Wordmark } from "@/components/icons";
import { openDownloadGate } from "@/lib/downloadGate";
import {
  AUTHOR_NAME,
  AUTHOR_URL,
  DOWNLOAD_NAME,
  DOWNLOAD_URL,
  EXTENSION_SETUP_URL,
  ISSUES_URL,
  README_URL,
  RELEASES_URL,
  REPO_URL,
  RUN_FROM_SOURCE_URL,
} from "@/lib/site";
import { Shell } from "@/styles/GlobalStyles";
import {
  Credit,
  FooterBottom,
  FooterBrand,
  FooterColumn,
  FooterColumns,
  FooterHeading,
  FooterLink,
  FooterName,
  FooterRoot,
  FooterTag,
  FooterTop,
} from "./Footer.styles";

const COLUMNS = [
  {
    head: "Product",
    links: [
      { label: "Features", href: "#features" },
      { label: "Gallery", href: "#gallery" },
      { label: "Privacy", href: "#privacy" },
      { label: "Requirements", href: "#requirements" },
      { label: "FAQ", href: "#faq" },
    ],
  },
  {
    head: "Get it",
    links: [
      { label: "Download for macOS", href: DOWNLOAD_URL, download: DOWNLOAD_NAME },
      { label: "All releases", href: RELEASES_URL, external: true },
      { label: "Run from source", href: RUN_FROM_SOURCE_URL, external: true },
      { label: "Chrome extension", href: EXTENSION_SETUP_URL, external: true },
    ],
  },
  {
    head: "Project",
    links: [
      { label: "GitHub repository", href: REPO_URL, external: true },
      { label: "Read me", href: README_URL, external: true },
      { label: "Report an issue", href: ISSUES_URL, external: true },
    ],
  },
];

export function Footer() {
  return (
    <FooterRoot>
      <Shell>
        <FooterTop>
          <FooterBrand>
            <FooterName>
              <Wordmark size={22} />
              AngelNotch
            </FooterName>
            <FooterTag>
              A local-first macOS utility that turns the MacBook notch into a compact, expandable
              workspace.
            </FooterTag>
          </FooterBrand>

          <FooterColumns>
            {COLUMNS.map((column) => (
              <FooterColumn key={column.head} aria-label={column.head}>
                <FooterHeading>{column.head}</FooterHeading>
                {column.links.map((link) => (
                  <FooterLink
                    key={link.label}
                    href={"download" in link ? "#download" : link.href}
                    {...("download" in link ? { onClick: openDownloadGate } : {})}
                    {...("external" in link && link.external
                      ? { target: "_blank", rel: "noreferrer" }
                      : {})}
                  >
                    {link.label}
                  </FooterLink>
                ))}
              </FooterColumn>
            ))}
          </FooterColumns>
        </FooterTop>

        <FooterBottom>
          <span>AngelNotch · macOS only · Open source</span>
          <Credit>
            Made with ❤️ by{" "}
            <a href={AUTHOR_URL} target="_blank" rel="noreferrer">
              {AUTHOR_NAME}
            </a>
          </Credit>
        </FooterBottom>
      </Shell>
    </FooterRoot>
  );
}
