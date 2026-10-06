"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";
import { initialCreateProjectState, type CreateProjectState } from "./state";

export type { CreateProjectState } from "./state";

function normalizeProjectName(value: FormDataEntryValue | null) {
  const name = typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
  if (!name) return { ok: false as const, error: "Indiquez le nom du projet." };
  if (name.length > 180) return { ok: false as const, error: "Le nom du projet ne peut pas dépasser 180 caractères." };
  return { ok: true as const, value: name };
}

function normalizeDescription(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return null;
  const description = value.trim().replace(/\r\n/g, "\n");
  return description || null;
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export async function createProject(
  _previousState: CreateProjectState = initialCreateProjectState,
  formData: FormData
): Promise<CreateProjectState> {
  const parsedName = normalizeProjectName(formData.get("name"));
  const description = normalizeDescription(formData.get("description"));
  const submitted = { name: typeof formData.get("name") === "string" ? String(formData.get("name")) : "", description: typeof formData.get("description") === "string" ? String(formData.get("description")) : "" };
  if (!parsedName.ok) return { status: "error", message: parsedName.error, values: submitted };

  const attemptId = String(formData.get("attempt_id") ?? "");
  if (!isUuid(attemptId)) return { status: "error", message: "Cette tentative de création n’est plus valide. Rechargez la page puis réessayez.", values: submitted };

  const identity = await getCurrentIdentity();
  if (!identity.userId) return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.", values: submitted };
  if (
    !identity.organization
    || (identity.organization.accessLevel !== "owner" && identity.organization.accessLevel !== "full")
  ) {
    return { status: "error", message: "Vous n’avez pas les droits nécessaires pour créer un projet dans cette structure.", values: submitted };
  }

  const supabase = await createClient();

  const { data: existing, error: existingError } = await supabase
    .from("projects")
    .select("id")
    .eq("id", attemptId)
    .eq("organization_id", identity.organization.id)
    .maybeSingle();
  if (!existingError && existing) {
    revalidatePath("/", "layout");
    return { status: "success", message: "Projet créé", projectId: attemptId, values: { name: parsedName.value, description: description ?? "" } };
  }

  const { error } = await supabase
    .from("projects")
    .insert({
      id: attemptId,
      organization_id: identity.organization.id,
      name: parsedName.value,
      description,
      created_by: identity.userId,
    });

  if (error) {
    const { data: recovered } = await supabase.from("projects").select("id").eq("id", attemptId).eq("organization_id", identity.organization.id).maybeSingle();
    if (!recovered) return { status: "error", message: "Le projet n’a pas pu être créé. Vérifiez votre connexion puis réessayez.", values: submitted };
  }

  revalidatePath("/", "layout");
  return { status: "success", message: "Projet créé", projectId: attemptId, values: { name: parsedName.value, description: description ?? "" } };
}
