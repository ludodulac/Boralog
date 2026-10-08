"use client";

import { useActionState } from "react";
import { saveProfile, type ProfileFormState } from "./actions";

const initialState: ProfileFormState = { status: "idle", message: "" };

export function ProfileForm({
  displayName,
  professionalEmail,
  professionalPhone,
}: {
  displayName: string;
  professionalEmail: string;
  professionalPhone: string;
}) {
  const [state, action, pending] = useActionState(saveProfile, initialState);

  return <form className="profile-form" action={action} aria-busy={pending}>
    <label>
      Nom affiché
      <input name="display_name" defaultValue={displayName} maxLength={120} autoComplete="name" disabled={pending}/>
    </label>
    <label>
      Email professionnel
      <input name="professional_email" type="email" defaultValue={professionalEmail} maxLength={254} autoComplete="email" inputMode="email" disabled={pending}/>
      <span>Adresse professionnelle du profil. Elle ne modifie pas votre email de connexion.</span>
    </label>
    <label>
      Téléphone professionnel
      <input name="professional_phone" type="tel" defaultValue={professionalPhone} maxLength={80} autoComplete="tel" inputMode="tel" disabled={pending}/>
    </label>
    {state.message && <p className={state.status === "error" ? "profile-feedback error" : "profile-feedback"} role={state.status === "error" ? "alert" : "status"}>{state.message}</p>}
    <button className="profile-save" type="submit" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
  </form>;
}
