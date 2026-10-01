export type Line = { price: number; qty: number };

export function subtotal(lines: Line[]): number {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}

export function discount(total: number, code?: string): number {
  if (!code) return total;
  if (code === "SAVE10") return total * 0.9;
  if (code === "HALF") return total * 0.5;
  return total;
}

export function shipping(total: number, country: string): number {
  if (country !== "US") return 1500;
  return total >= 5000 ? 0 : 500;
}

export function formatCents(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}
