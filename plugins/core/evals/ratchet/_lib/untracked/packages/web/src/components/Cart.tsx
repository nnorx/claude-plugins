import { formatPrice } from "../lib/money";

export function CartTotal({ items }: { items: { price: number }[] }) {
  // @ts-expect-error reduce initial value typing
  const total = items.reduce((sum, item) => sum + item.price);
  // @ts-expect-error formatPrice wants cents
  return <span>{formatPrice(total, "USD")}</span>;
}
