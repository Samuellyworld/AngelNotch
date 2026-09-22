import { keyframes, styled } from "styled-components";

const wake = keyframes`
  0%, 7% { filter: brightness(0.38); }
  13%, 100% { filter: brightness(1); }
`;

const notchState = keyframes`
  0%, 14% { width: 26%; background: #050505; box-shadow: none; }
  22%, 54% { width: 43%; background: #070707; box-shadow: 0 10px 34px rgba(133, 179, 179, 0.18); }
  64%, 82% { width: 36%; background: #0a100c; box-shadow: 0 10px 34px rgba(148, 179, 158, 0.22); }
  92%, 100% { width: 26%; background: #050505; box-shadow: none; }
`;

const notchPulse = keyframes`
  0%, 18% { opacity: 0; transform: scale(0.6); }
  26%, 51% { opacity: 1; transform: scale(1); background: var(--cyan); }
  62%, 78% { opacity: 1; transform: scale(1.2); background: var(--mint); }
  90%, 100% { opacity: 0; transform: scale(0.6); }
`;

const faceState = keyframes`
  0%, 17% { opacity: 0; transform: translateY(10px) scale(0.94); }
  25%, 55% { opacity: 1; transform: none; }
  65%, 100% { opacity: 0; transform: translateY(-8px) scale(1.03); }
`;

const scan = keyframes`
  0%, 23% { opacity: 0; transform: translateY(-5rem); }
  29% { opacity: 1; }
  52% { opacity: 1; transform: translateY(5rem); }
  58%, 100% { opacity: 0; transform: translateY(5rem); }
`;

const unlock = keyframes`
  0%, 55% { color: var(--ink-tertiary); transform: scale(0.88); opacity: 0.62; }
  64%, 82% { color: var(--mint); transform: scale(1.08); opacity: 1; }
  92%, 100% { color: var(--ink-tertiary); transform: scale(0.88); opacity: 0.62; }
`;

const firstStatus = keyframes`
  0%, 16% { opacity: 1; transform: none; }
  22%, 100% { opacity: 0; transform: translateY(-8px); }
`;

const secondStatus = keyframes`
  0%, 19% { opacity: 0; transform: translateY(8px); }
  26%, 54% { opacity: 1; transform: none; }
  61%, 100% { opacity: 0; transform: translateY(-8px); }
`;

const thirdStatus = keyframes`
  0%, 58% { opacity: 0; transform: translateY(8px); }
  66%, 84% { opacity: 1; transform: none; }
  92%, 100% { opacity: 0; transform: translateY(-8px); }
`;

const stageEntrance = keyframes`
  from { opacity: 0.5; transform: translateY(12px) scale(0.985); }
  to { opacity: 1; transform: none; }
`;

export const DemoGrid = styled.div`
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(280px, 0.8fr);
  gap: clamp(2rem, 1rem + 4vw, 5rem);
  align-items: center;

  @media (max-width: 880px) {
    grid-template-columns: 1fr;
  }
`;

export const DemoCard = styled.div`
  position: relative;
  padding: clamp(1rem, 0.6rem + 1.4vw, 1.7rem);
  border: 1px solid var(--outline);
  border-radius: var(--r-card);
  background:
    radial-gradient(80% 80% at 50% 0%, rgba(133, 179, 179, 0.13), transparent 70%),
    var(--surface-quiet);
  box-shadow: 0 35px 80px -55px rgba(0, 0, 0, 1);
`;

export const DemoStage = styled.div<{ $playing: boolean }>`
  min-height: 390px;
  padding: clamp(1rem, 0.4rem + 2vw, 2rem);
  border-radius: 17px;
  background:
    radial-gradient(circle at 50% 36%, rgba(133, 179, 179, 0.12), transparent 28%),
    linear-gradient(145deg, #181b1b, #0b0c0c 72%);
  animation: ${stageEntrance} 800ms var(--ease-out) both;
  animation-play-state: ${({ $playing }) => ($playing ? "running" : "paused")};
  will-change: opacity, transform;

  * {
    animation-play-state: ${({ $playing }) => ($playing ? "running" : "paused")};
  }
`;

export const MacBody = styled.div`
  width: min(100%, 580px);
  margin: 0 auto;
  padding: 7px 7px 17px;
  border-radius: 18px 18px 9px 9px;
  background: linear-gradient(145deg, #343536, #151616 55%, #474849);
  box-shadow: 0 30px 55px -30px rgba(0, 0, 0, 0.95);
`;

export const MacScreen = styled.div`
  position: relative;
  display: flex;
  min-height: 320px;
  flex-direction: column;
  align-items: center;
  overflow: hidden;
  border-radius: 12px 12px 5px 5px;
  background:
    radial-gradient(circle at 50% 42%, rgba(57, 76, 76, 0.72), transparent 31%),
    linear-gradient(145deg, #192021, #080a0a 76%);
  animation: ${wake} 7s var(--ease-inout) infinite;

  &::after {
    position: absolute;
    inset: 0;
    background: linear-gradient(115deg, transparent 28%, rgba(255, 255, 255, 0.035), transparent 60%);
    content: "";
    pointer-events: none;
  }
`;

export const Notch = styled.div`
  position: relative;
  z-index: 4;
  display: grid;
  width: 26%;
  height: 34px;
  place-items: center;
  border-radius: 0 0 18px 18px;
  background: #050505;
  animation: ${notchState} 7s var(--ease-inout) infinite;

  span {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    animation: ${notchPulse} 7s var(--ease-inout) infinite;
  }
`;

export const FaceFrame = styled.div`
  position: relative;
  display: grid;
  width: 128px;
  height: 148px;
  place-items: center;
  overflow: hidden;
  margin-top: 32px;
  border: 1px solid rgba(133, 179, 179, 0.52);
  border-radius: 42% 42% 36% 36%;
  box-shadow:
    inset 0 0 36px rgba(133, 179, 179, 0.06),
    0 0 40px rgba(133, 179, 179, 0.08);
  animation: ${faceState} 7s var(--ease-inout) infinite;
`;

export const FaceSilhouette = styled.div`
  position: relative;
  width: 72px;
  height: 88px;
  border-radius: 45% 45% 48% 48%;
  background: linear-gradient(145deg, rgba(243, 237, 227, 0.22), rgba(243, 237, 227, 0.06));

  &::before,
  &::after {
    position: absolute;
    top: 34px;
    width: 8px;
    height: 3px;
    border-radius: 50%;
    background: rgba(243, 237, 227, 0.62);
    content: "";
  }

  &::before { left: 17px; }
  &::after { right: 17px; }

  span {
    position: absolute;
    bottom: 21px;
    left: 50%;
    width: 20px;
    height: 7px;
    border-bottom: 2px solid rgba(243, 237, 227, 0.45);
    border-radius: 50%;
    transform: translateX(-50%);
  }
`;

export const ScanBeam = styled.div`
  position: absolute;
  left: 8px;
  width: calc(100% - 16px);
  height: 2px;
  background: var(--cyan);
  box-shadow: 0 0 12px 4px rgba(133, 179, 179, 0.48);
  animation: ${scan} 7s linear infinite;
`;

export const LockGlyph = styled.div`
  position: absolute;
  top: 64px;
  right: clamp(1rem, 4vw, 3rem);
  display: grid;
  width: 44px;
  height: 44px;
  place-items: center;
  border: 1px solid var(--outline);
  border-radius: 14px;
  background: rgba(9, 9, 8, 0.52);
  animation: ${unlock} 7s var(--ease-inout) infinite;
`;

export const StatusStack = styled.div`
  position: relative;
  width: 100%;
  height: 22px;
  margin-top: 18px;
  color: var(--ink-secondary);
  font-family: var(--font-mono);
  font-size: 0.65rem;
  letter-spacing: 0.08em;
  text-align: center;
  text-transform: uppercase;

  span {
    position: absolute;
    inset: 0;
  }

  span:nth-child(1) { animation: ${firstStatus} 7s var(--ease-inout) infinite; }
  span:nth-child(2) { animation: ${secondStatus} 7s var(--ease-inout) infinite; }
  span:nth-child(3) { animation: ${thirdStatus} 7s var(--ease-inout) infinite; color: var(--mint); }
`;

export const DemoCopy = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1.7rem;
`;

export const Steps = styled.ol`
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
`;

export const Step = styled.li`
  display: grid;
  grid-template-columns: 2.2rem 1fr;
  gap: 1rem;

  > span {
    padding-top: 0.12rem;
    color: var(--accent);
    font-family: var(--font-mono);
    font-size: 0.7rem;
  }

  strong {
    display: block;
    margin-bottom: 0.3rem;
    font-size: 1.02rem;
    font-weight: 500;
  }

  p {
    color: var(--ink-secondary);
    font-size: 0.92rem;
    line-height: 1.55;
  }
`;

export const SecurityNote = styled.div`
  display: flex;
  gap: 0.8rem;
  padding: 1rem;
  border: 1px solid rgba(209, 171, 107, 0.2);
  border-radius: 15px;
  background: rgba(209, 171, 107, 0.055);
  color: var(--sun);

  svg { flex: 0 0 auto; margin-top: 0.1rem; }

  p {
    color: var(--ink-secondary);
    font-size: 0.82rem;
    line-height: 1.55;
  }
`;
