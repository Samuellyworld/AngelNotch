import type { IconName } from "@/components/icons";

/** How a feature is illustrated.
 *  - "capture" is a retina screenshot of the running app, shown as a close-up.
 *  - "mockup"  is a still from the product demo, shown inside its macbook.
 *  - "mark"    is used where no honest screenshot exists yet; the card leans on
 *              the drawn glyph instead of inventing an interface. */
export type ShotKind = "capture" | "mockup" | "mark";

export type Feature = {
  id: string;
  /** Displayed as a two-digit index in the section rail. */
  index: string;
  title: string;
  blurb: string;
  icon: IconName;
  /** CSS custom property name for the mark colour. */
  tint: string;
  kind: ShotKind;
  shot?: string;
  alt?: string;
};

export const FEATURES: Feature[] = [
  {
    id: "media",
    index: "01",
    title: "Media controls",
    blurb:
      "Play, pause and skip Spotify, Apple Music, YouTube and YouTube Music without leaving the window you are in.",
    icon: "media",
    tint: "--spotify",
    kind: "capture",
    shot: "/shots/panel-media-live.webp",
    alt: "The live AngelNotch media panel showing Spotify playback, track details, a progress bar, transport controls, volume and audio output.",
  },
  {
    id: "clipboard",
    index: "02",
    title: "Clipboard history",
    blurb:
      "Search everything you have copied. Pin what you keep needing, preview it, copy it back or clear it.",
    icon: "clipboard",
    tint: "--sun",
    kind: "capture",
    shot: "/shots/panel-clipboard.webp",
    alt: "The clipboard panel listing four recently copied items with timestamps, a search field, a preview pane and copy, pin and delete buttons.",
  },
  {
    id: "focus",
    index: "03",
    title: "Focus timer",
    blurb:
      "Configurable sessions with bundled voice announcements that work entirely offline.",
    icon: "focus",
    tint: "--accent",
    kind: "mockup",
    shot: "/shots/panel-focus.webp",
    alt: "A twenty-five minute focus session in the notch with start, skip and reset controls and a note that two sessions have been completed.",
  },
  {
    id: "system",
    index: "04",
    title: "System controls",
    blurb:
      "Volume, brightness, microphone state and audio output — without opening a single settings panel.",
    icon: "system",
    tint: "--violet",
    kind: "mockup",
    shot: "/shots/panel-system.webp",
    alt: "Volume and brightness sliders beside microphone, camera and battery tiles, with MacBook Pro Speakers selected as the audio output.",
  },
  {
    id: "indicators",
    index: "05",
    title: "Live indicators",
    blurb:
      "Battery, connected AirPods, camera and microphone use, and active calls — readable without opening anything.",
    icon: "pulse",
    tint: "--mint",
    kind: "capture",
    shot: "/shots/panel-home.webp",
    alt: "The home panel showing the frontmost app, a battery reading of 33 percent with one hour twenty minutes remaining, and quick access shortcuts.",
  },
  {
    id: "files",
    index: "06",
    title: "File shelf",
    blurb:
      "Park the files you keep reaching for. Preview with Quick Look, then send them on with Share or AirDrop.",
    icon: "shelf",
    tint: "--blue",
    kind: "mark",
  },
  {
    id: "calendar",
    index: "07",
    title: "Calendar",
    blurb: "Your next event sits in the notch, with one click through to supported meeting links.",
    icon: "calendar",
    tint: "--cyan",
    kind: "mark",
  },
  {
    id: "activities",
    index: "08",
    title: "Live activities",
    blurb: "Watch a Chrome download fill up in the notch instead of hunting for the window.",
    icon: "activity",
    tint: "--accent",
    kind: "mark",
  },
  {
    id: "context",
    index: "09",
    title: "Contextual actions",
    blurb: "Quick actions rearrange themselves to match whichever app you are working in.",
    icon: "context",
    tint: "--cream",
    kind: "mark",
  },
];

/** The four states the pinned hero scrubs through, keyed to frame positions in
 *  the pre-rendered hero sequence. */
export type HeroBeat = { at: number; kicker: string; line: string };

export const HERO_BEATS: HeroBeat[] = [
  { at: 0.0, kicker: "Idle", line: "It waits in the notch, the size of nothing." },
  { at: 0.3, kicker: "Media", line: "Reach up. Your music is already there." },
  { at: 0.52, kicker: "Clipboard", line: "Everything you copied, still yours." },
  { at: 0.72, kicker: "Focus", line: "Twenty-five minutes, announced out loud." },
  { at: 0.88, kicker: "System", line: "Volume, brightness, mic, output. Done." },
];

/** Panels shown in the interactive gallery, in tab order. */
export type GalleryView = {
  id: string;
  tab: string;
  caption: string;
  shot: string;
  alt: string;
  real: boolean;
};

export const GALLERY: GalleryView[] = [
  {
    id: "home",
    tab: "Home",
    caption: "Battery, the frontmost app, and four shortcuts.",
    shot: "/shots/panel-home.webp",
    alt: "The home panel with a battery reading, a quick access heading and shortcuts for clipboard, files, focus and system.",
    real: true,
  },
  {
    id: "clipboard",
    tab: "Clipboard",
    caption: "Search, preview, pin, copy back, remove.",
    shot: "/shots/panel-clipboard.webp",
    alt: "The clipboard panel with a search field, a list of copied items and a preview pane with copy, pin and delete buttons.",
    real: true,
  },
  {
    id: "media",
    tab: "Media",
    caption: "Artwork, scrubber, transport, volume.",
    shot: "/shots/panel-media-live.webp",
    alt: "The live media panel showing Spotify playback, track information, a position scrubber and transport controls.",
    real: true,
  },
  {
    id: "focus",
    tab: "Focus",
    caption: "A countdown that stays visible when collapsed.",
    shot: "/shots/panel-focus.webp",
    alt: "The focus panel showing a twenty-five minute countdown with start, skip and reset buttons.",
    real: false,
  },
  {
    id: "system",
    tab: "System",
    caption: "Sliders, input state and output device.",
    shot: "/shots/panel-system.webp",
    alt: "The system panel with volume and brightness sliders, microphone and camera tiles and an audio output picker.",
    real: false,
  },
];

export type Shortcut = { label: string; keys: string[] };

export const SHORTCUTS: Shortcut[] = [
  { label: "Open or close AngelNotch", keys: ["⌥", "Space"] },
  { label: "Open clipboard history", keys: ["⌃", "⌥", "V"] },
  { label: "Start a screenshot", keys: ["⌃", "⌥", "S"] },
];

export const PRIVACY_CLAIMS = [
  "No in-app account",
  "No in-app analytics",
  "No advertising",
  "No in-app tracking SDKs",
  "No cloud clipboard",
] as const;

export type Permission = { name: string; purpose: string; icon: IconName };

export const PERMISSIONS: Permission[] = [
  { name: "Automation", purpose: "Read and control Spotify or Apple Music", icon: "media" },
  { name: "Calendar", purpose: "Show the next event and its meeting link", icon: "calendar" },
  { name: "Microphone", purpose: "Display microphone and active-call status", icon: "pulse" },
  { name: "Camera", purpose: "Display a camera-in-use indicator", icon: "shield" },
];

export type Requirement = { label: string; detail: string; icon: IconName };

export const REQUIREMENTS: Requirement[] = [
  {
    label: "macOS 14 or newer",
    detail: "Sonoma and later. Earlier versions are not supported.",
    icon: "apple",
  },
  {
    label: "A MacBook",
    detail: "Best on a model with a display notch, where the panel has a home to grow from.",
    icon: "laptop",
  },
  {
    label: "Node.js and npm",
    detail: "Only needed if you install or develop the optional Chrome extension.",
    icon: "terminal",
  },
];

export type Faq = { q: string; a: string };

export const FAQS: Faq[] = [
  {
    q: "Does AngelNotch upload my clipboard history?",
    a: "No. Clipboard history stays on your Mac. There is no cloud clipboard and nothing is synced anywhere.",
  },
  {
    q: "Does it record my camera or microphone?",
    a: "No. AngelNotch does not record, store, transcribe or transmit camera or microphone content. During a call it may sample local microphone amplitude only to draw the compact waveform.",
  },
  {
    q: "Do I need the Chrome extension?",
    a: "No. The extension is optional. It adds YouTube playback information and Chrome download progress, and every other feature works without it.",
  },
  {
    q: "Which music services are supported?",
    a: "Spotify, Apple Music, YouTube and YouTube Music.",
  },
  {
    q: "Which version of macOS is required?",
    a: "macOS 14 or newer.",
  },
  {
    q: "Does AngelNotch require an account?",
    a: "No. The Mac app has no sign-up or login. The website asks for an email before download only so AngelNotch can send release notes and product updates; it does not create an app account.",
  },
  {
    q: "What happens to my email when I download?",
    a: "It is added to the AngelNotch product update list in Brevo. It is used for release notes and occasional product emails, and every message includes an unsubscribe option.",
  },
  {
    q: "Can I run it from source?",
    a: "Yes. The repository has build and development instructions, and the whole project is open on GitHub.",
  },
];
