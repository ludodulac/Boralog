"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../../lib/supabase/server";
import { isUuid, normalizeOrganizationName, organizationSlug } from "../../../lib/organization-onboarding";

export type CreateOrganizationState = {
  status: "idle" | "success" | "error";
  message: string;
};

export const initialCreateOrganizationState: CreateOrganizationState = { status: "idle", message: "" };

export async function createOrganization(
  _previousState: CreateOrganizationState = initialCreateOrganizationState,
  formData: FormData
): Promise<CreateOrganizationState> {
  const parsedName = normalizeOrganizationName(formData.get("name"));
  if ("error" in parsedName) return { status: "error", message: parsedName.error };

  const attemptId = String(formData.get("attempt_id") ?? "");
  if (!isUuid(attemptId)) return { status: "error", message: "Cette tentative de création n’est plus valide. Rechargez la page puis réessayez." };

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) {
    return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez." };
  }

  // Recovery first: the previous HTTP response may have been lost after COMMIT.
  const { data: existing, error: existingError } = await supabase
    .from("organizations")
    .select("id, name")
    .eq("id", attemptId)
    .maybeSingle();

  if (!existingError && existing) {
    revalidatePath("/", "layout");
    return { status: "success", message: "Structure créée" };
  }

  const { data: organization, error } = await supabase
    .from("organizations")
    .insert({
      id: attemptId,
      name: parsedName.value,
      slug: organizationSlug(parsedName.value, attemptId),
      created_by: authData.user.id,
    })
    .select("id")
    .maybeSingle();

  if (error || !organization) {
    // One last RLS-scoped read distinguishes an unknown/lost response from a true failure.
    const { data: recovered } = await supabase
      .from("organizations")
      .select("id")
      .eq("id", attemptId)
      .maybeSingle();
    if (!recovered) return { status: "error", message: "La structure n’a pas pu être créée. Vérifiez votre connexion puis réessayez." };
  }

  revalidatePath("/", "layout");
  return { status: "success", message: "Structure créée" };
}
