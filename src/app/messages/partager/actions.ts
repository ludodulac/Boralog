"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";
import { initialSharedMessageState, type SharedMessageState } from "./state";

export async function createSharedMessage(
  _previousState: SharedMessageState = initialSharedMessageState,
  formData: FormData,
): Promise<SharedMessageState> {
  const content = String(formData.get("content") ?? "").trim().replace(/\r\n/g, "\n");
  const sourceKind = formData.get("source_kind");

  if (!content) return { status: "error", message: "Le texte partagé est vide." };
  if (sourceKind !== "WHATSAPP" && sourceKind !== "OTHER") {
    return { status: "error", message: "Choisissez la source du message." };
  }

  const identity = await getCurrentIdentity();
  if (!identity.userId) return { status: "error", message: "Votre session n’est plus valide." };
  if (
    !identity.organization
    || (identity.organization.accessLevel !== "owner" && identity.organization.accessLevel !== "full")
  ) {
    return { status: "error", message: "Vous n’avez pas les droits nécessaires pour enregistrer ce message." };
  }

  const supabase = await createClient();
  const { error } = await supabase.from("messages").insert({
    organization_id: identity.organization.id,
    project_id: null,
    event_id: null,
    content,
    status: "TO_PROCESS",
    created_by: identity.userId,
    origin_type: "EXTERNAL_MANUAL",
    author_user_id: null,
    external_author_label: null,
    source_kind: sourceKind,
    source_occurred_at: null,
    visibility: "ORGANIZATION",
  });

  if (error) return { status: "error", message: "Le message partagé n’a pas pu être enregistré." };

  revalidatePath("/");
  revalidatePath("/messages");
  return { status: "success", message: "Message enregistré." };
}
