"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../../../lib/auth";
import { createClient } from "../../../../lib/supabase/server";
import { initialProjectEditState, type ProjectEditState } from "./state";

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

export async function updateProject(
  _previousState: ProjectEditState = initialProjectEditState,
  formData: FormData,
): Promise<ProjectEditState> {
  const projectId = String(formData.get("project_id") ?? "");
  if (!isUuid(projectId)) return { status: "error", message: "Projet invalide." };

  const parsedName = normalizeProjectName(formData.get("name"));
  if (!parsedName.ok) return { status: "error", message: parsedName.error };
  const description = normalizeDescription(formData.get("description"));

  const identity = await getCurrentIdentity();
  if (!identity.userId) return { status: "error", message: "Votre session n’est plus valide." };
  if (
    !identity.organization
    || (identity.organization.accessLevel !== "owner" && identity.organization.accessLevel !== "full")
  ) {
    return { status: "error", message: "Vous n’avez pas les droits nécessaires pour modifier ce projet." };
  }

  const supabase = await createClient();
  const { data: project, error: projectError } = await supabase
    .from("projects")
    .select("id")
    .eq("id", projectId)
    .eq("organization_id", identity.organization.id)
    .maybeSingle();

  if (projectError || !project) {
    return { status: "error", message: "Ce projet n’appartient pas à votre Structure courante." };
  }

  const { error } = await supabase
    .from("projects")
    .update({
      name: parsedName.value,
      description,
    })
    .eq("id", projectId)
    .eq("organization_id", identity.organization.id);

  if (error) return { status: "error", message: "Le projet n’a pas pu être modifié." };

  revalidatePath("/");
  revalidatePath("/projets");
  revalidatePath(`/projets/reel/${projectId}`);
  return { status: "success", message: "Projet mis à jour." };
}
