export function Search({ onQuery }: { onQuery: (q: string) => void }) {
  // @ts-expect-error event typing
  return <input onChange={(e) => onQuery(e.target.value.trim())} />;
}
