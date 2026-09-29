"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../lib/supabase/server";
import { initialCreateMessageState, type CreateMessageState } from "./state";

export type { CreateMessageState } from "./state";

function normalizeContent(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return "";
  return value.trim().replace(/\r\n/g, "\n");
}

export async function createMessage(
  _previousState: CreateMessageState = initialCreateMessageState,
  formData: FormData
): Promise<CreateMessageState> {
  const content = normalizeContent(formData.get("content"));
  const values = { content };

  if (!content) {
    return { status: "error", message: "Écrivez le message à traiter.", values };
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) {
    return {
      status: "error",
      message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.",
      values,
    };
  }

  const { data: memberships, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("organization_id, access_level")
    .eq("user_id", authData.user.id)
    .eq("status", "active")
    .in("access_level", ["owner", "full"])
    .limit(1);

  const membership = memberships?.[0];
  if (membershipError || !membership) {
    return {
      status: "error",
      message: "Vous n’avez pas les droits nécessaires pour créer un message de structure.",
      values,
    };
  }

  const { error } = await supabase.from("messages").insert({
    organization_id: membership.organization_id,
    content,
    created_by: authData.user.id,
  });

  if (error) {
    return {
      status: "error",
      message: "Le message n’a pas pu être enregistré. Vérifiez votre connexion puis réessayez.",
      values,
    };
  }

  revalidatePath("/messages");
  return { status: "success", message: "Message enregistré.", values: { content: "" } };
}
