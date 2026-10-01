// Deprecated: use apiClient. Kept until the last callers move.
export const legacyFetch = (path: string) =>
  fetch(`/legacy${path}`).then((res) => res.json());
