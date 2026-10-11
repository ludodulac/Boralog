"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";
import { initialSharedMessageState, type SharedMessageState } from "./state";

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export async function createSharedMessage(
  _previousState: SharedMessageState = initialSharedMessageState,
  formData: FormData,
): Promise<SharedMessageState> {
  const content = String(formData.get("content") ?? "").trim().replace(/\r\n/g, "\n");
  const sourceKind = formData.get("source_kind");
  const senderMode = formData.get("sender_mode");
  const senderPersonId = String(formData.get("sender_person_id") ?? "").trim();
  const externalAuthorLabel = String(formData.get("external_author_label") ?? "").trim();

  if (!content) return { status: "error", message: "Le texte partagé est vide." };
  if (sourceKind !== "WHATSAPP" && sourceKind !== "OTHER") {
    return { status: "error", message: "Choisissez la source du message." };
  }
  if (senderMode !== "PERSON" && senderMode !== "UNREGISTERED" && senderMode !== "UNKNOWN") {
    return { status: "error", message: "Choisissez l’expéditeur." };
  }
  if (senderPersonId && externalAuthorLabel) {
    return { status: "error", message: "Choisissez une Personne BORALOG ou un nom libre, pas les deux." };
  }
  if (senderMode === "PERSON" && !senderPersonId) {
    return { status: "error", message: "Sélectionnez une Personne BORALOG." };
  }
  if (senderMode === "UNREGISTERED" && !externalAuthorLabel) {
    return { status: "error", message: "Saisissez le nom de la personne non enregistrée." };
  }
  if (senderMode === "UNKNOWN" && (senderPersonId || externalAuthorLabel)) {
    return { status: "error", message: "Un expéditeur inconnu ne doit pas contenir de nom." };
  }
  if (externalAuthorLabel.length > 160) {
    return { status: "error", message: "Le nom de l’expéditeur est trop long." };
  }
  if (senderPersonId && !isUuid(senderPersonId)) {
    return { status: "error", message: "La Personne sélectionnée n’est pas valide." };
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

  if (senderPersonId) {
    const { data: person, error: personError } = await supabase
      .from("people")
      .select("id")
      .eq("id", senderPersonId)
      .eq("organization_id", identity.organization.id)
      .maybeSingle();

    if (personError || !person) {
      return { status: "error", message: "La Personne sélectionnée n’appartient pas à cette Structure." };
    }
  }

  const { error } = await supabase.from("messages").insert({
    organization_id: identity.organization.id,
    project_id: null,
    event_id: null,
    content,
    status: "TO_PROCESS",
    created_by: identity.userId,
    origin_type: "EXTERNAL_MANUAL",
    author_user_id: null,
    external_author_person_id: senderPersonId || null,
    external_author_label: externalAuthorLabel || null,
    source_kind: sourceKind,
    source_occurred_at: null,
    visibility: "ORGANIZATION",
  });

  if (error) return { status: "error", message: "Le message partagé n’a pas pu être enregistré." };

  revalidatePath("/");
  revalidatePath("/messages");
  return { status: "success", message: "Message enregistré." };
}
