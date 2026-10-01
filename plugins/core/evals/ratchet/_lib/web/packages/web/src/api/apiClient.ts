export const apiClient = {
  get: (path: string) => fetch(`/api${path}`).then((res) => res.json()),
};
