import { legacyFetch } from "../api/legacy";

export async function loadCheckout(cartId: string) {
  const cart = await legacyFetch(`/carts/${cartId}`);
  const rates = await legacyFetch(`/shipping/rates?cart=${cartId}`);
  return { cart, rates };
}
