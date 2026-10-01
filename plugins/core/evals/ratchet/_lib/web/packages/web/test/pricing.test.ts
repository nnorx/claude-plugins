import { test } from "node:test";
import assert from "node:assert/strict";
import { subtotal, discount, shipping } from "../src/lib/pricing.ts";

test("subtotal", () => assert.equal(subtotal([{ price: 100, qty: 2 }]), 200));
test("discount", () => {
  assert.equal(discount(1000), 1000);
  assert.equal(discount(1000, "SAVE10"), 900);
});
test("shipping", () => assert.equal(shipping(6000, "US"), 0));
