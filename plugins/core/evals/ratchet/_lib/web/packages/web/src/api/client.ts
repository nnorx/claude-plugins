import { legacyFetch } from "./legacy";

export const getUser = (id: string) => legacyFetch(`/users/${id}`);
export const getCart = (id: string) => legacyFetch(`/carts/${id}`);
export const getWishlist = (id: string) => legacyFetch(`/wishlists/${id}`);
