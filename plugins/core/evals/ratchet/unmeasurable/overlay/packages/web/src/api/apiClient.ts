const DEFAULT_TIMEOUT_MS = 5000;

export const apiClient = {
  get: (path: string) => fetch(`/api${path}`).then((res) => res.json()),
};
