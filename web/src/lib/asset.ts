/** Resolves a path in public/ against the deployed base.
 *
 *  Vite is configured with a relative base, so the built site works unchanged
 *  from the web root, from a sub-path, and straight off the filesystem. every
 *  Runtime asset references go through here rather than hard-coding a leading
 *  slash. */
export function asset(path: string): string {
  const base = import.meta.env.BASE_URL;
  return `${base}${path.replace(/^\//, "")}`;
}
