export type IconName =
  | "media"
  | "clipboard"
  | "shelf"
  | "focus"
  | "calendar"
  | "system"
  | "pulse"
  | "activity"
  | "context"
  | "apple"
  | "laptop"
  | "terminal"
  | "github"
  | "download"
  | "star"
  | "shield"
  | "chrome"
  | "arrow"
  | "chevron"
  | "plus"
  | "notch";

type Props = {
  name: IconName;
  size?: number | undefined;
  /** CSS module lookups are typed as possibly undefined, so accept that here. */
  className?: string | undefined;
};

/** The shared silhouette: a rounded panel with a notch bitten out of the top. */
const PANEL = "M3.6 7.2a3.6 3.6 0 0 1 3.6-3.6h1.9v.9a2.9 2.9 0 0 0 2.9 2.9h0a2.9 2.9 0 0 0 2.9-2.9v-.9h1.9a3.6 3.6 0 0 1 3.6 3.6v9.6a3.6 3.6 0 0 1-3.6 3.6H7.2a3.6 3.6 0 0 1-3.6-3.6z";

const PATHS: Record<IconName, JSX.Element> = {
  notch: <path d={PANEL} />,

  media: (
    <>
      <path d={PANEL} />
      <path d="M8.4 15.4v-3.6M11.2 16.8v-6.4M14 14.6v-2.8M16.8 16.2v-5.6" />
    </>
  ),

  clipboard: (
    <>
      <path d={PANEL} />
      <path d="M7.6 11.6h6.2M7.6 14.6h4.1" />
      <path d="m14.9 15.9 2.4-2.4M17.3 15.9l-2.4-2.4" />
    </>
  ),

  shelf: (
    <>
      <path d={PANEL} />
      <path d="M6.6 15.4h10.8v1.2a1.8 1.8 0 0 1-1.8 1.8H8.4a1.8 1.8 0 0 1-1.8-1.8z" />
      <path d="M12 9.4v4.4M10.2 12.2 12 14l1.8-1.8" />
    </>
  ),

  focus: (
    <>
      <path d={PANEL} />
      <path d="M15.9 13.9a3.9 3.9 0 1 1-3.4-3.86" />
      <path d="M12 11.4v2.2l1.7 1" />
    </>
  ),

  calendar: (
    <>
      <path d={PANEL} />
      <path d="M3.9 10.6h16.2" />
      <path d="M7.9 14h1.6M7.9 17h1.6M12.4 14H14M12.4 17H14M16.6 14h.6" />
    </>
  ),

  system: (
    <>
      <path d={PANEL} />
      <path d="M6.8 11.9h4.3M13.6 11.9h3.6M6.8 16.1h2.6M11.9 16.1h5.3" />
      <circle cx="12.3" cy="11.9" r="1.4" />
      <circle cx="10.5" cy="16.1" r="1.4" />
    </>
  ),

  pulse: (
    <>
      <path d={PANEL} />
      <path d="M6.4 14h2.3l1.5-3 2 6 1.5-3h2.4" />
      <path d="M18.4 12.8v2.4" />
    </>
  ),

  activity: (
    <>
      <path d={PANEL} />
      <path d="M12 10.2v5M9.9 13.1 12 15.2l2.1-2.1" />
      <path d="M7.4 17.9h9.2" />
    </>
  ),

  context: (
    <>
      <path d={PANEL} />
      <rect x="6.8" y="11.4" width="4.4" height="2.6" rx="1.3" />
      <rect x="12.8" y="11.4" width="4.4" height="2.6" rx="1.3" />
      <path d="M6.8 17.2h5.9" />
    </>
  ),

  apple: (
    <>
      <path d="M16.1 12.4c0-2.2 1.8-3.2 1.9-3.3-1-1.5-2.6-1.7-3.2-1.8-1.4-.14-2.7.8-3.4.8s-1.8-.78-2.9-.76c-1.5.02-2.9.87-3.6 2.2-1.6 2.7-.4 6.8 1.1 9 .74 1.1 1.6 2.3 2.8 2.26 1.1-.05 1.5-.73 2.9-.73s1.7.73 2.9.7c1.2-.02 2-1.1 2.7-2.2.55-.8.86-1.6 1.05-2.2-.05-.02-2.2-.86-2.25-3.4z" />
      <path d="M13.9 5.6c.6-.75 1-1.8.9-2.85-.87.04-1.9.58-2.5 1.32-.55.65-1.04 1.72-.91 2.73.97.08 1.95-.5 2.5-1.2z" />
    </>
  ),

  laptop: (
    <>
      <path d="M5.4 6.6a1.8 1.8 0 0 1 1.8-1.8h9.6a1.8 1.8 0 0 1 1.8 1.8v9.2H5.4z" />
      <path d="M10.3 4.8h3.4v.5a1.7 1.7 0 0 1-1.7 1.7 1.7 1.7 0 0 1-1.7-1.7z" />
      <path d="M2.6 15.8h18.8l-1.1 2.5a1.8 1.8 0 0 1-1.65 1.1H5.35a1.8 1.8 0 0 1-1.65-1.1z" />
    </>
  ),

  terminal: (
    <>
      <rect x="3.4" y="4.8" width="17.2" height="14.4" rx="3.2" />
      <path d="m7.6 10.2 2.6 2.4-2.6 2.4M12.6 15.3h4.2" />
    </>
  ),

  github: (
    <path d="M12 2.6a9.4 9.4 0 0 0-3 18.3c.47.09.64-.2.64-.45v-1.6c-2.6.57-3.15-1.25-3.15-1.25-.43-1.08-1.04-1.37-1.04-1.37-.85-.58.06-.57.06-.57.94.07 1.43.97 1.43.97.84 1.43 2.2 1.02 2.73.78.09-.6.33-1.02.6-1.25-2.08-.24-4.26-1.04-4.26-4.62 0-1.02.36-1.86.96-2.51-.1-.24-.42-1.19.09-2.48 0 0 .78-.25 2.56.96a8.9 8.9 0 0 1 4.66 0c1.78-1.21 2.56-.96 2.56-.96.51 1.29.19 2.24.09 2.48.6.65.96 1.49.96 2.51 0 3.59-2.19 4.38-4.27 4.61.34.29.64.87.64 1.75v2.6c0 .25.17.55.65.45A9.4 9.4 0 0 0 12 2.6z" />
  ),

  download: (
    <>
      <path d="M12 3.8v10.4" />
      <path d="m7.9 10.4 4.1 4.1 4.1-4.1" />
      <path d="M4.4 16.2v1.9a2.2 2.2 0 0 0 2.2 2.2h10.8a2.2 2.2 0 0 0 2.2-2.2v-1.9" />
    </>
  ),

  star: (
    <path d="m12 3.8 2.6 5.3 5.8.85-4.2 4.1 1 5.8-5.2-2.73-5.2 2.73 1-5.8-4.2-4.1 5.8-.85z" />
  ),

  shield: (
    <>
      <path d="M12 3.4 4.8 6.2v5.5c0 4.3 3 7.5 7.2 8.9 4.2-1.4 7.2-4.6 7.2-8.9V6.2z" />
      <path d="m9 12.1 2.2 2.2 4-4.4" />
    </>
  ),

  chrome: (
    <>
      <circle cx="12" cy="12" r="8.6" />
      <circle cx="12" cy="12" r="3.5" />
      <path d="M15 9.4h6.1M9.4 13.7 6.3 19M14.6 13.7l-3 5.9" />
    </>
  ),

  arrow: <path d="M4.6 12h14.2m-5.2-5.4L18.8 12l-5.2 5.4" />,

  chevron: <path d="m7.2 9.4 4.8 4.8 4.8-4.8" />,

  plus: <path d="M12 5.6v12.8M5.6 12h12.8" />,
};

const FILLED: ReadonlySet<IconName> = new Set(["apple", "github"]);

export function Icon({ name, size = 22, className }: Props) {
  const filled = FILLED.has(name);

  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? "currentColor" : "none"}
      stroke={filled ? "none" : "currentColor"}
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {PATHS[name]}
    </svg>
  );
}

/** The product mark, redrawn from resources/app-icon.svg. */
export function Wordmark({ size = 26, animated = false }: { size?: number; animated?: boolean }) {
  const gradientId = `an-loop-${useId().replace(/:/g, "")}`;
  const path =
    "M512 512C410 266 317 133 246 799C72 799 102 256 512 512C614 758 707 891 778 225C952 225 922 768 512 512";

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 1024 1024"
      aria-hidden="true"
      focusable="false"
      style={{ display: "block", flexShrink: 0 }}
    >
      <defs>
        <linearGradient
          id={gradientId}
          x1="-280"
          y1="790"
          x2="390"
          y2="250"
          gradientUnits="userSpaceOnUse"
        >
          <animate
            attributeName="x1"
            values="-280;620;-280"
            dur="4.8s"
            repeatCount="indefinite"
          />
          <animate
            attributeName="x2"
            values="390;1290;390"
            dur="4.8s"
            repeatCount="indefinite"
          />
          <stop offset="0" stopColor="#C68168" />
          <stop offset=".42" stopColor="#E98563" />
          <stop offset=".58" stopColor="#F1B76D" />
          <stop offset="1" stopColor="#D57A5D" />
        </linearGradient>
      </defs>
      <path
        d={path}
        fill="none"
        stroke={`url(#${gradientId})`}
        strokeWidth="96"
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity={animated ? 0.76 : 1}
      />
      {animated ? (
        <path
          d={path}
          fill="none"
          pathLength="1"
          stroke="#ffb06d"
          strokeWidth="42"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeDasharray="0.08 0.92"
          data-logo-pulse=""
        >
          <animate
            attributeName="stroke-dashoffset"
            values="0;-1"
            dur="2.9s"
            repeatCount="indefinite"
          />
        </path>
      ) : null}
    </svg>
  );
}
import { useId } from "react";
