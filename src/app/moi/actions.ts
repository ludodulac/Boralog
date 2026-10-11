"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../lib/supabase/server";

export type ProfileFormState = {
  status: "idle" | "success" | "error";
  message: string;
};

const initialState: ProfileFormState = { status: "idle", message: "" };

function optionalText(value: FormDataEntryValue | null, maxLength: number) {
  const normalized = String(value ?? "").trim();
  if (!normalized) return { value: null };
  if (normalized.length > maxLength) return { error: `Ce champ ne peut pas dépasser ${maxLength} caractères.` };
  return { value: normalized };
}

function validEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export async function saveProfile(
  _previousState: ProfileFormState = initialState,
  formData: FormData
): Promise<ProfileFormState> {
  const displayName = optionalText(formData.get("display_name"), 120);
  if ("error" in displayName) return { status: "error", message: `Nom affiché : ${displayName.error}` };

  const professionalEmail = optionalText(formData.get("professional_email"), 254);
  if ("error" in professionalEmail) return { status: "error", message: `Email professionnel : ${professionalEmail.error}` };
  if (professionalEmail.value && !validEmail(professionalEmail.value)) {
    return { status: "error", message: "Saisissez une adresse email professionnelle valide." };
  }

  const professionalPhone = optionalText(formData.get("professional_phone"), 80);
  if ("error" in professionalPhone) return { status: "error", message: `Téléphone professionnel : ${professionalPhone.error}` };

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) {
    return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez." };
  }

  const { data, error } = await supabase
    .from("profiles")
    .update({
      display_name: displayName.value,
      professional_email: professionalEmail.value,
      professional_phone: professionalPhone.value,
    })
    .eq("id", authData.user.id)
    .select("id")
    .maybeSingle();

  if (error || !data) {
    return { status: "error", message: "Le profil n’a pas pu être enregistré. Réessayez." };
  }

  revalidatePath("/moi");
  return { status: "success", message: "Profil enregistré" };
}
