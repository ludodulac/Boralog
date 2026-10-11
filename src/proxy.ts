import { NextResponse, type NextRequest } from "next/server";
import { updateSession } from "./lib/supabase/proxy";

export async function proxy(request: NextRequest) {
  if ((request.nextUrl.pathname === "/demo/organisation" || request.nextUrl.pathname === "/demo/projets")) {
    const headers = new Headers(request.headers);
    headers.set("x-boralog-internal-demo-route", request.nextUrl.pathname === "/demo/projets" ? "projets" : "organisation");
    return NextResponse.next({ request: { headers } });
  }
  // Never trust a client-supplied demo marker on any protected route.
  request.headers.delete("x-boralog-internal-demo-route");

  const isPublicTechnicalRoute =
    request.nextUrl.pathname === "/partager/android"
    || request.nextUrl.pathname === "/manifest.webmanifest";

  if (isPublicTechnicalRoute) {
    return NextResponse.next();
  }

  const { response, authenticated } = await updateSession(request);
  const isAuthRoute = request.nextUrl.pathname.startsWith("/auth");

  if (!authenticated && !isAuthRoute) {
    const url = request.nextUrl.clone();
    url.pathname = "/auth/connexion";
    url.searchParams.set("retour", request.nextUrl.pathname + request.nextUrl.search);
    const redirect = NextResponse.redirect(url);
    response.cookies.getAll().forEach((cookie) => redirect.cookies.set(cookie));
    return redirect;
  }

  if (authenticated && (request.nextUrl.pathname === "/auth/connexion" || request.nextUrl.pathname === "/auth/inscription")) {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    url.search = "";
    const redirect = NextResponse.redirect(url);
    response.cookies.getAll().forEach((cookie) => redirect.cookies.set(cookie));
    return redirect;
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
