"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  createCompanyForPerson,
  initialPersonFormState,
  setPersonCompany,
  setPersonMembership,
  updatePerson,
} from "../actions";

function RefreshOnSuccess({ status }: { status: string }) {
  const router = useRouter();
  useEffect(() => {
    if (status === "success") router.refresh();
  }, [router, status]);
  return null;
}

export function PersonBusinessForm({
  person,
}: {
  person: {
    id: string;
    name: string;
    role_label: string | null;
    professional_email: string | null;
    professional_phone: string | null;
  };
}) {
  const [state, action, pending] = useActionState(updatePerson, initialPersonFormState);
  return <form className="person-form" action={action}>
    <RefreshOnSuccess status={state.status} />
    <input type="hidden" name="person_id" value={person.id} />
    <label>Nom <input name="name" required maxLength={160} defaultValue={person.name} disabled={pending} /></label>
    <label>Rôle professionnel <input name="role_label" maxLength={160} defaultValue={person.role_label ?? ""} disabled={pending} /></label>
    <label>E-mail professionnel <input name="professional_email" type="email" maxLength={254} defaultValue={person.professional_email ?? ""} disabled={pending} /></label>
    <label>Téléphone professionnel <input name="professional_phone" type="tel" maxLength={80} defaultValue={person.professional_phone ?? ""} disabled={pending} /></label>
    {state.status !== "idle" && <p className={`person-feedback ${state.status === "error" ? "error" : ""}`} role={state.status === "error" ? "alert" : "status"}>{state.message}</p>}
    <button className="person-submit" type="submit" disabled={pending}>{pending ? "Enregistrement…" : "Enregistrer"}</button>
  </form>;
}

export function CompanyLinkControls({
  personId,
  companies,
  linkedCompanyIds,
}: {
  personId: string;
  companies: { id: string; name: string }[];
  linkedCompanyIds: string[];
}) {
  const [linkState, linkAction, linkPending] = useActionState(setPersonCompany, initialPersonFormState);
  const [createState, createAction, createPending] = useActionState(createCompanyForPerson, initialPersonFormState);
  return <div className="person-stack">
    <RefreshOnSuccess status={linkState.status} />
    <RefreshOnSuccess status={createState.status} />
    <div className="person-company-list">
      {companies.length === 0 ? <p className="work-empty">Aucune Compagnie disponible.</p> : companies.map((company) => {
        const linked = linkedCompanyIds.includes(company.id);
        return <form action={linkAction} className="person-inline-row" key={company.id}>
          <input type="hidden" name="person_id" value={personId} />
          <input type="hidden" name="company_id" value={company.id} />
          <input type="hidden" name="mode" value={linked ? "unlink" : "link"} />
          <span>{company.name}</span>
          <button type="submit" disabled={linkPending}>{linked ? "Retirer" : "Associer"}</button>
        </form>;
      })}
    </div>
    {linkState.status === "error" && <p className="person-feedback error" role="alert">{linkState.message}</p>}
    <form className="person-inline-create" action={createAction}>
      <input type="hidden" name="person_id" value={personId} />
      <label>Nouvelle Compagnie
        <input name="company_name" required maxLength={160} placeholder="Nom de la Compagnie" disabled={createPending} />
      </label>
      <button type="submit" disabled={createPending}>{createPending ? "Création…" : "Créer et associer"}</button>
    </form>
    {createState.status !== "idle" && <p className={`person-feedback ${createState.status === "error" ? "error" : ""}`} role={createState.status === "error" ? "alert" : "status"}>{createState.message}</p>}
  </div>;
}

export function AccountLinkControls({
  personId,
  linkedMembershipId,
  linkedLabel,
  memberships,
}: {
  personId: string;
  linkedMembershipId: string | null;
  linkedLabel: string | null;
  memberships: { id: string; label: string }[];
}) {
  const [state, action, pending] = useActionState(setPersonMembership, initialPersonFormState);
  return <div className="person-stack">
    <RefreshOnSuccess status={state.status} />
    <p className="person-account-summary">{linkedMembershipId ? `Compte lié : ${linkedLabel || "Membre Boralog"}` : "Aucun compte lié"}</p>
    {linkedMembershipId ? (
      <form action={action}>
        <input type="hidden" name="person_id" value={personId} />
        <input type="hidden" name="mode" value="unlink" />
        <button className="person-secondary-button" type="submit" disabled={pending}>Délier le compte</button>
      </form>
    ) : (
      <form className="person-inline-create" action={action}>
        <input type="hidden" name="person_id" value={personId} />
        <input type="hidden" name="mode" value="link" />
        <label>Compte Boralog actif
          <select name="membership_id" required defaultValue="" disabled={pending}>
            <option value="" disabled>Choisir un compte</option>
            {memberships.map((membership) => <option key={membership.id} value={membership.id}>{membership.label}</option>)}
          </select>
        </label>
        <button type="submit" disabled={pending}>Lier</button>
      </form>
    )}
    {state.status !== "idle" && <p className={`person-feedback ${state.status === "error" ? "error" : ""}`} role={state.status === "error" ? "alert" : "status"}>{state.message}</p>}
  </div>;
}
