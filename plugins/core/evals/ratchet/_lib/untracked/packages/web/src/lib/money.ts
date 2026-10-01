export function formatPrice(cents: number) {
  // @ts-expect-error Intl typing on older lib
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(cents / 100);
}
