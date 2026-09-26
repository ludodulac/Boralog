import test from "node:test";
import assert from "node:assert/strict";
import { NextRequest, NextResponse } from "next/server.js";

type CookieToSet = { name: string; value: string; options?: Parameters<NextResponse["cookies"]["set"]>[2] };

function exact040SetAll(request: NextRequest, initial: NextResponse, cookiesToSet: CookieToSet[]) {
  let response = initial;
  cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
  response = NextResponse.next({ request });
  cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
  return response;
}

test("TEMPORARY DO NOT MERGE 046 A: no incoming cookie is stable", () => {
  const request = new NextRequest("https://example.invalid/");
  const response = NextResponse.next({ request });
  assert.equal(request.cookies.getAll().length, 0);
  assert.equal(response.cookies.getAll().length, 0);
});

test("TEMPORARY DO NOT MERGE 046 B: synthetic incoming cookie copies without exception", () => {
  const request = new NextRequest("https://example.invalid/", { headers: { cookie: "synthetic=incoming" } });
  const response = exact040SetAll(request, NextResponse.next({ request }), [{ name: "synthetic", value: "refreshed", options: { path: "/" } }]);
  assert.equal(request.cookies.get("synthetic")?.value, "refreshed");
  assert.equal(response.cookies.get("synthetic")?.value, "refreshed");
});

test("TEMPORARY DO NOT MERGE 046 C: multiple cookies and options survive on response", () => {
  const request = new NextRequest("https://example.invalid/");
  const response = exact040SetAll(request, NextResponse.next({ request }), [
    { name: "sb-synthetic-a", value: "a", options: { path: "/", httpOnly: true, sameSite: "lax", secure: true } },
    { name: "sb-synthetic-b", value: "b", options: { path: "/x", maxAge: 123 } },
  ]);
  const a = response.cookies.get("sb-synthetic-a");
  const b = response.cookies.get("sb-synthetic-b");
  assert.equal(a?.value, "a"); assert.equal(a?.path, "/"); assert.equal(a?.httpOnly, true); assert.equal(a?.sameSite, "lax"); assert.equal(a?.secure, true);
  assert.equal(b?.value, "b"); assert.equal(b?.path, "/x"); assert.equal(b?.maxAge, 123);
});

test("TEMPORARY DO NOT MERGE 046 D: final response is the replacement created by last setAll", () => {
  const request = new NextRequest("https://example.invalid/");
  const initial = NextResponse.next({ request });
  initial.headers.set("x-old-response", "stale");
  const final = exact040SetAll(request, initial, [{ name: "sb-synthetic", value: "new", options: { path: "/" } }]);
  assert.notEqual(final, initial);
  assert.equal(final.headers.get("x-old-response"), null);
  assert.equal(final.cookies.get("sb-synthetic")?.value, "new");
});

test("TEMPORARY DO NOT MERGE 046 E: request mutation is represented in request passed to NextResponse.next", () => {
  const request = new NextRequest("https://example.invalid/", { headers: { cookie: "before=1" } });
  const final = exact040SetAll(request, NextResponse.next({ request }), [{ name: "sb-synthetic", value: "after", options: { path: "/" } }]);
  assert.equal(request.cookies.get("sb-synthetic")?.value, "after");
  const override = final.headers.get("x-middleware-request-cookie");
  assert.ok(override?.includes("sb-synthetic=after"), "NextResponse must forward mutated Cookie header upstream");
});
