"use server";

import { revalidatePath } from "next/cache";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";
import { initialPersonFormState, type PersonFormState } from "./state";

function readString(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim() : "";
}

function optionalText(value: FormDataEntryValue | null, maxLength: number) {
  const text = readString(value);
  if (!text) return { ok: true as const, value: null };
  if (text.length > maxLength) return { ok: false as const, error: `Maximum ${maxLength} caractères.` };
  return { ok: true as const, value: text };
}

function validEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

async function getActorContext() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) {
    return { ok: false as const, message: "Votre session n’est plus valide." };
  }
  if (
    !identity.organization
    || (identity.organization.accessLevel !== "owner" && identity.organization.accessLevel !== "full")
  ) {
    return { ok: false as const, message: "Vous n’avez pas accès à la gestion des Personnes." };
  }

  const supabase = await createClient();
  return {
    ok: true as const,
    supabase,
    userId: identity.userId,
    organizationId: identity.organization.id,
  };
}

async function personBelongsToOrganization(
  supabase: Awaited<ReturnType<typeof createClient>>,
  personId: string,
  organizationId: string,
) {
  const { data } = await supabase
    .from("people")
    .select("id")
    .eq("id", personId)
    .eq("organization_id", organizationId)
    .maybeSingle();
  return Boolean(data);
}

export async function createPerson(
  _previousState: PersonFormState = initialPersonFormState,
  formData: FormData,
): Promise<PersonFormState> {
  const name = readString(formData.get("name")).replace(/\s+/g, " ");
  if (!name) return { status: "error", message: "Indiquez le nom de la Personne." };
  if (name.length > 160) return { status: "error", message: "Le nom ne peut pas dépasser 160 caractères." };

  const roleLabel = optionalText(formData.get("role_label"), 160);
  const professionalEmail = optionalText(formData.get("professional_email"), 254);
  const professionalPhone = optionalText(formData.get("professional_phone"), 80);
  if (!roleLabel.ok || !professionalEmail.ok || !professionalPhone.ok) {
    return { status: "error", message: "Un champ dépasse la longueur autorisée." };
  }
  if (professionalEmail.value && !validEmail(professionalEmail.value)) {
    return { status: "error", message: "Saisissez un e-mail professionnel valide." };
  }

  const actor = await getActorContext();
  if (!actor.ok) return { status: "error", message: actor.message };

  const { data, error } = await actor.supabase
    .from("people")
    .insert({
      organization_id: actor.organizationId,
      name,
      role_label: roleLabel.value,
      professional_email: professionalEmail.value,
      professional_phone: professionalPhone.value,
      created_by: actor.userId,
    })
    .select("id")
    .single();

  if (error || !data) return { status: "error", message: "La Personne n’a pas pu être créée." };

  revalidatePath("/personnes");
  return { status: "success", message: "Personne créée.", personId: data.id };
}

export async function updatePerson(
  _previousState: PersonFormState = initialPersonFormState,
  formData: FormData,
): Promise<PersonFormState> {
  const personId = readString(formData.get("person_id"));
  if (!isUuid(personId)) return { status: "error", message: "Personne invalide." };

  const name = readString(formData.get("name")).replace(/\s+/g, " ");
  if (!name || name.length > 160) return { status: "error", message: "Nom invalide." };

  const roleLabel = optionalText(formData.get("role_label"), 160);
  const professionalEmail = optionalText(formData.get("professional_email"), 254);
  const professionalPhone = optionalText(formData.get("professional_phone"), 80);
  if (!roleLabel.ok || !professionalEmail.ok || !professionalPhone.ok) {
    return { status: "error", message: "Un champ dépasse la longueur autorisée." };
  }
  if (professionalEmail.value && !validEmail(professionalEmail.value)) {
    return { status: "error", message: "Saisissez un e-mail professionnel valide." };
  }

  const actor = await getActorContext();
  if (!actor.ok) return { status: "error", message: actor.message };
  if (!await personBelongsToOrganization(actor.supabase, personId, actor.organizationId)) {
    return { status: "error", message: "Personne inaccessible." };
  }

  const { error } = await actor.supabase
    .from("people")
    .update({
      name,
      role_label: roleLabel.value,
      professional_email: professionalEmail.value,
      professional_phone: professionalPhone.value,
    })
    .eq("id", personId)
    .eq("organization_id", actor.organizationId);

  if (error) return { status: "error", message: "La Personne n’a pas pu être modifiée." };

  revalidatePath("/personnes");
  revalidatePath(`/personnes/${personId}`);
  return { status: "success", message: "Personne mise à jour." };
}

export async function setPersonCompany(
  _previousState: PersonFormState = initialPersonFormState,
  formData: FormData,
): Promise<PersonFormState> {
  const personId = readString(formData.get("person_id"));
  const companyId = readString(formData.get("company_id"));
  const mode = readString(formData.get("mode"));
  if (!isUuid(personId) || !isUuid(companyId) || !["link", "unlink"].includes(mode)) {
    return { status: "error", message: "Association invalide." };
  }

  const actor = await getActorContext();
  if (!actor.ok) return { status: "error", message: actor.message };
  if (!await personBelongsToOrganization(actor.supabase, personId, actor.organizationId)) {
    return { status: "error", message: "Personne inaccessible." };
  }

  const { data: company } = await actor.supabase
    .from("companies")
    .select("id")
    .eq("id", companyId)
    .eq("organization_id", actor.organizationId)
    .maybeSingle();
  if (!company) return { status: "error", message: "Compagnie inaccessible." };

  const query = mode === "link"
    ? actor.supabase.from("person_companies").insert({ person_id: personId, company_id: companyId })
    : actor.supabase.from("person_companies").delete().eq("person_id", personId).eq("company_id", companyId);

  const { error } = await query;
  if (error && !(mode === "link" && error.code === "23505")) {
    return { status: "error", message: "L’association Compagnie n’a pas pu être modifiée." };
  }

  revalidatePath("/personnes");
  revalidatePath(`/personnes/${personId}`);
  return { status: "success", message: mode === "link" ? "Compagnie associée." : "Compagnie retirée." };
}

export async function createCompanyForPerson(
  _previousState: PersonFormState = initialPersonFormState,
  formData: FormData,
): Promise<PersonFormState> {
  const personId = readString(formData.get("person_id"));
  const name = readString(formData.get("company_name")).replace(/\s+/g, " ");
  if (!isUuid(personId) || !name || name.length > 160) {
    return { status: "error", message: "Nom de Compagnie invalide." };
  }

  const actor = await getActorContext();
  if (!actor.ok) return { status: "error", message: actor.message };
  if (!await personBelongsToOrganization(actor.supabase, personId, actor.organizationId)) {
    return { status: "error", message: "Personne inaccessible." };
  }

  const { data: company, error: companyError } = await actor.supabase
    .from("companies")
    .insert({
      organization_id: actor.organizationId,
      name,
      created_by: actor.userId,
    })
    .select("id")
    .single();

  if (companyError || !company) {
    return { status: "error", message: "Cette Compagnie existe peut-être déjà ou n’a pas pu être créée." };
  }

  const { error: linkError } = await actor.supabase
    .from("person_companies")
    .insert({ person_id: personId, company_id: company.id });

  if (linkError) return { status: "error", message: "Compagnie créée, mais l’association a échoué." };

  revalidatePath("/personnes");
  revalidatePath(`/personnes/${personId}`);
  return { status: "success", message: "Compagnie créée et associée." };
}

export async function setPersonMembership(
  _previousState: PersonFormState = initialPersonFormState,
  formData: FormData,
): Promise<PersonFormState> {
  const personId = readString(formData.get("person_id"));
  const membershipId = readString(formData.get("membership_id"));
  const mode = readString(formData.get("mode"));
  if (!isUuid(personId) || !["link", "unlink"].includes(mode)) {
    return { status: "error", message: "Liaison de compte invalide." };
  }

  const actor = await getActorContext();
  if (!actor.ok) return { status: "error", message: actor.message };
  if (!await personBelongsToOrganization(actor.supabase, personId, actor.organizationId)) {
    return { status: "error", message: "Personne inaccessible." };
  }

  let nextMembershipId: string | null = null;
  if (mode === "link") {
    if (!isUuid(membershipId)) return { status: "error", message: "Choisissez un compte actif." };
    const { data: membership } = await actor.supabase
      .from("organization_memberships")
      .select("id")
      .eq("id", membershipId)
      .eq("organization_id", actor.organizationId)
      .eq("status", "active")
      .maybeSingle();
    if (!membership) return { status: "error", message: "Ce compte actif n’est pas disponible dans cette Structure." };
    nextMembershipId = membership.id;
  }

  const { error } = await actor.supabase
    .from("people")
    .update({ organization_membership_id: nextMembershipId })
    .eq("id", personId)
    .eq("organization_id", actor.organizationId);

  if (error) {
    return { status: "error", message: "Le compte Boralog n’a pas pu être lié. Il est peut-être déjà associé à une autre Personne." };
  }

  revalidatePath("/personnes");
  revalidatePath(`/personnes/${personId}`);
  return { status: "success", message: mode === "link" ? "Compte Boralog lié." : "Compte Boralog délié." };
}
