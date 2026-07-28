import type { AnchorHTMLAttributes, CSSProperties, ReactNode } from "react";

import { Icon, type IconName } from "@/components/icons";
import { useReveal } from "@/hooks/useReveal";
import { Shell } from "@/styles/GlobalStyles";
import {
  ButtonAnchor,
  ButtonMeta,
  Frame,
  FrameDot,
  FrameImage,
  FrameTag,
  Key,
  KeysWrap,
  RevealBlock,
  SectionHead,
  SectionLede,
  SectionRail,
  SectionRailIndex,
  SectionRoot,
  SectionTitle,
  type ButtonVariant,
} from "./styles";

/* ---------- button ---------- */

type ButtonProps = AnchorHTMLAttributes<HTMLAnchorElement> & {
  variant?: ButtonVariant | undefined;
  size?: "default" | "small" | undefined;
  icon?: IconName | undefined;
  trailing?: IconName | undefined;
  meta?: string | undefined;
  children: ReactNode;
};

export function Button({
  variant = "primary",
  size = "default",
  icon,
  trailing,
  meta,
  children,
  className,
  onPointerMove,
  ...rest
}: ButtonProps) {
  const trackPointer: AnchorHTMLAttributes<HTMLAnchorElement>["onPointerMove"] = (event) => {
    const rect = event.currentTarget.getBoundingClientRect();
    event.currentTarget.style.setProperty("--hover-x", `${event.clientX - rect.left}px`);
    event.currentTarget.style.setProperty("--hover-y", `${event.clientY - rect.top}px`);
    onPointerMove?.(event);
  };

  return (
    <ButtonAnchor
      $variant={variant}
      $small={size === "small"}
      className={className}
      onPointerMove={trackPointer}
      {...rest}
    >
      {icon ? <Icon name={icon} size={17} /> : null}
      <span>{children}</span>
      {meta ? <ButtonMeta>{meta}</ButtonMeta> : null}
      {trailing ? <Icon name={trailing} size={16} data-slide="" /> : null}
    </ButtonAnchor>
  );
}

/* ---------- reveal ---------- */

export function Reveal({
  children,
  delay = 0,
  className,
  style,
}: {
  children: ReactNode;
  delay?: number | undefined;
  className?: string | undefined;
  style?: CSSProperties | undefined;
}) {
  const { ref, shown } = useReveal<HTMLDivElement>();

  return (
    <RevealBlock
      ref={ref}
      $shown={shown}
      $delay={delay}
      className={className}
      style={style}
    >
      {children}
    </RevealBlock>
  );
}

/* ---------- section ---------- */

export function Section({
  id,
  index,
  label,
  title,
  lede,
  children,
  className,
}: {
  id?: string | undefined;
  index?: string | undefined;
  label?: string | undefined;
  title?: ReactNode | undefined;
  lede?: ReactNode | undefined;
  children: ReactNode;
  className?: string | undefined;
}) {
  return (
    <SectionRoot id={id} className={className}>
      <Shell>
        {label ? (
          <SectionHead>
            <Reveal>
              <SectionRail>
                {index ? <SectionRailIndex>{index}</SectionRailIndex> : null}
                <span>{label}</span>
              </SectionRail>
            </Reveal>
            {title ? (
              <Reveal delay={70}>
                <SectionTitle>{title}</SectionTitle>
              </Reveal>
            ) : null}
            {lede ? (
              <Reveal delay={140}>
                <SectionLede>{lede}</SectionLede>
              </Reveal>
            ) : null}
          </SectionHead>
        ) : null}
        {children}
      </Shell>
    </SectionRoot>
  );
}

/* ---------- keycap ---------- */

export function Keys({ keys }: { keys: string[] }) {
  return (
    <KeysWrap>
      {keys.map((key) => (
        <Key key={key}>{key}</Key>
      ))}
    </KeysWrap>
  );
}

/* ---------- screen frame ---------- */

export function ScreenFrame({
  src,
  alt,
  tag,
  loading = "lazy",
  className,
}: {
  src: string;
  alt: string;
  tag?: string | undefined;
  loading?: "lazy" | "eager" | undefined;
  className?: string | undefined;
}) {
  return (
    <Frame className={className}>
      <FrameImage src={src} alt={alt} loading={loading} decoding="async" />
      {tag ? (
        <FrameTag>
          <FrameDot />
          {tag}
        </FrameTag>
      ) : null}
    </Frame>
  );
}
