"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../lib/auth";
import { normalizeOrganizationName } from "../../lib/organization-onboarding";
import { createClient } from "../../lib/supabase/server";
import { initialStructureRenameState, type StructureRenameState } from "./state";

export async function renameCurrentOrganization(
  _previousState: StructureRenameState = initialStructureRenameState,
  formData: FormData,
): Promise<StructureRenameState> {
  const identity = await getCurrentIdentity();

  if (!identity.userId) {
    return { status: "error", message: "Votre session n’est plus valide." };
  }

  if (!identity.organization) {
    return { status: "error", message: "Aucune Structure courante n’est disponible." };
  }

  if (identity.organization.accessLevel !== "owner") {
    return { status: "error", message: "Seul un OWNER peut renommer la Structure." };
  }

  const normalized = normalizeOrganizationName(formData.get("name"));
  if (!normalized.ok) {
    return { status: "error", message: normalized.error };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .from("organizations")
    .update({ name: normalized.value })
    .eq("id", identity.organization.id);

  if (error) {
    return { status: "error", message: "Le nom de la Structure n’a pas pu être modifié." };
  }

  revalidatePath("/", "layout");
  revalidatePath("/parametres");
  return { status: "success", message: "Nom de la Structure mis à jour." };
}
