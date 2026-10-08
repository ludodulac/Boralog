import test from "node:test";
import assert from "node:assert/strict";
import {
  BORALOG_TIME_ZONE,
  formatBoralogDateTime,
} from "../src/lib/date-time.ts";

test("BORALOG datetime display uses Europe/Paris summer time", () => {
  assert.equal(BORALOG_TIME_ZONE, "Europe/Paris");
  const displayed = formatBoralogDateTime("2026-07-15T12:00:00.000Z", "short");
  assert.match(displayed, /14:00/);
});

test("BORALOG datetime display uses Europe/Paris winter time", () => {
  const displayed = formatBoralogDateTime("2026-01-15T12:00:00.000Z", "short");
  assert.match(displayed, /13:00/);
});
