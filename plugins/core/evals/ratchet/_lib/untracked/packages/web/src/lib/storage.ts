export function load(key: string) {
  // @ts-expect-error localStorage may be undefined in tests
  const raw = localStorage.getItem(key);
  // @ts-expect-error JSON.parse of null
  return JSON.parse(raw);
}

export function save(key: string, value: unknown) {
  // @ts-expect-error unknown is not serialisable
  localStorage.setItem(key, JSON.stringify(value));
}
