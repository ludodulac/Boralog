import { NextResponse, type NextRequest } from "next/server";
import { updateSession } from "./src/lib/supabase/proxy";

export async function proxy(request: NextRequest) {
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
