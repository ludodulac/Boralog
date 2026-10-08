export const SHARED_MESSAGE_STORAGE_KEY = "boralog:shared-message:v1";

export function buildSharedMessageDraft(input: {
  title?: string | null;
  text?: string | null;
  url?: string | null;
}) {
  const title = input.title?.trim() ?? "";
  const text = input.text?.trim() ?? "";
  const url = input.url?.trim() ?? "";
  const primary = text || url;
  if (!primary) return "";
  if (title && !primary.toLocaleLowerCase().includes(title.toLocaleLowerCase())) {
    return `${title}\n\n${primary}`;
  }
  return primary;
}

export function safeInternalReturnPath(value: unknown) {
  if (typeof value !== "string") return "/";
  const candidate = value.trim();
  if (!candidate.startsWith("/") || candidate.startsWith("//") || candidate.includes("\\")) return "/";
  try {
    const parsed = new URL(candidate, "https://boralog.invalid");
    if (parsed.origin !== "https://boralog.invalid") return "/";
    return `${parsed.pathname}${parsed.search}${parsed.hash}`;
  } catch {
    return "/";
  }
}
