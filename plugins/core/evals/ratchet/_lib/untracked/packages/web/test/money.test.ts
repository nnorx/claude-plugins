import { test } from "node:test";
import assert from "node:assert/strict";
import { formatPrice } from "../src/lib/money.ts";

test("formatPrice", () => assert.equal(formatPrice(1999), "$19.99"));
