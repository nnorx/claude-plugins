import { legacyFetch } from "../api/legacy";

export async function loadAccount(id: string) {
  return legacyFetch(`/accounts/${id}`);
}
