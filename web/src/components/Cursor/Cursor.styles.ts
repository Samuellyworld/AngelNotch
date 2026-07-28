import { styled } from "styled-components";

const CursorPart = styled.span`
  position: fixed;
  top: 0;
  left: 0;
  display: block;
  pointer-events: none;
  will-change: transform, width, height;
`;

/**
 * A warm-metal take on the familiar pointer silhouette. Keeping the hotspot
 * at the arrow tip makes it accurate without falling back to a generic dot.
 */
export const CursorPointer = styled(CursorPart)`
  z-index: 1;
  width: 18px;
  height: 24px;
  background: linear-gradient(145deg, var(--cream) 5%, #f1b176 48%, var(--accent-deep) 100%);
  clip-path: polygon(
    0 0,
    1px 20px,
    6.1px 15.2px,
    10.3px 23px,
    14.2px 20.9px,
    10px 13.3px,
    17px 12.7px
  );
  filter:
    drop-shadow(0 1px 0 rgba(9, 9, 8, 0.9))
    drop-shadow(0 4px 6px rgba(0, 0, 0, 0.38));
  transform-origin: 0 0;
  transition:
    filter 220ms ease,
    opacity 180ms ease;
`;

/**
 * The follower borrows the product's panel silhouette: a soft rectangle with
 * a camera-notch cut into its top edge. It reads as AngelNotch, not a reticle.
 */
export const CursorNotch = styled(CursorPart)`
  width: 34px;
  height: 28px;
  border: 1px solid rgba(232, 133, 97, 0.52);
  border-radius: 11px;
  background: rgba(232, 133, 97, 0.035);
  box-shadow:
    inset 0 0 0 1px rgba(243, 237, 227, 0.08),
    0 8px 25px rgba(0, 0, 0, 0.18);
  opacity: 0.66;
  transition:
    width 360ms var(--ease-out),
    height 360ms var(--ease-out),
    border-radius 360ms var(--ease-out),
    border-color 260ms ease,
    background-color 260ms ease,
    box-shadow 260ms ease,
    opacity 220ms ease;

  &::before {
    position: absolute;
    top: -1px;
    left: 50%;
    width: 13px;
    height: 5px;
    border: 1px solid rgba(232, 133, 97, 0.52);
    border-top: 0;
    border-radius: 0 0 7px 7px;
    background: var(--canvas);
    content: "";
    transform: translateX(-50%);
    transition:
      width 360ms var(--ease-out),
      height 360ms var(--ease-out),
      border-color 260ms ease;
  }
`;

export const CursorRoot = styled.div`
  position: fixed;
  inset: 0;
  z-index: 1000;
  opacity: 0;
  pointer-events: none;
  transition: opacity 180ms ease;

  &[data-visible="true"] {
    opacity: 1;
  }

  &[data-interactive="true"] ${CursorNotch} {
    width: 62px;
    height: 42px;
    border-radius: 15px;
    border-color: var(--accent);
    background: rgba(232, 133, 97, 0.11);
    box-shadow:
      inset 0 0 0 1px rgba(243, 237, 227, 0.12),
      0 12px 32px rgba(0, 0, 0, 0.26),
      0 0 30px rgba(232, 133, 97, 0.12);
    opacity: 1;
  }

  &[data-interactive="true"] ${CursorNotch}::before {
    width: 20px;
    height: 7px;
    border-color: var(--accent);
  }

  &[data-interactive="true"] ${CursorPointer} {
    filter:
      drop-shadow(0 1px 0 rgba(9, 9, 8, 0.9))
      drop-shadow(0 0 8px rgba(232, 133, 97, 0.5));
  }

  &[data-pressed="true"] ${CursorNotch} {
    width: 46px;
    height: 32px;
    background: rgba(232, 133, 97, 0.2);
  }

  &[data-pressed="true"] ${CursorPointer} {
    opacity: 0.76;
  }

  @media (hover: none), (pointer: coarse), (prefers-reduced-motion: reduce) {
    display: none;
  }
`;
