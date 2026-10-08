"use client";

import { useMemo, useState } from "react";

export type PersonSenderOption = {
  id: string;
  name: string;
  role_label: string | null;
};

type SenderMode = "PERSON" | "UNREGISTERED" | "UNKNOWN";

export function PersonSenderCombobox({ people }: { people: PersonSenderOption[] }) {
  const [mode, setMode] = useState<SenderMode>("UNKNOWN");
  const [query, setQuery] = useState("");
  const [selectedPersonId, setSelectedPersonId] = useState("");
  const [open, setOpen] = useState(false);

  const filteredPeople = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase("fr");
    if (!needle) return people;
    return people.filter((person) =>
      person.name.toLocaleLowerCase("fr").includes(needle)
      || (person.role_label ?? "").toLocaleLowerCase("fr").includes(needle)
    );
  }, [people, query]);

  function chooseMode(nextMode: SenderMode) {
    setMode(nextMode);
    if (nextMode !== "PERSON") {
      setQuery("");
      setSelectedPersonId("");
      setOpen(false);
    }
  }

  return <fieldset className="message-audience">
    <legend>Expéditeur</legend>

    <label className="message-audience-choice">
      <input
        type="radio"
        name="sender_mode"
        value="PERSON"
        checked={mode === "PERSON"}
        onChange={() => chooseMode("PERSON")}
      />
      <span>Personne BORALOG</span>
    </label>

    <label className="message-audience-choice">
      <input
        type="radio"
        name="sender_mode"
        value="UNREGISTERED"
        checked={mode === "UNREGISTERED"}
        onChange={() => chooseMode("UNREGISTERED")}
      />
      <span>Personne non enregistrée</span>
    </label>

    <label className="message-audience-choice">
      <input
        type="radio"
        name="sender_mode"
        value="UNKNOWN"
        checked={mode === "UNKNOWN"}
        onChange={() => chooseMode("UNKNOWN")}
      />
      <span>Inconnu</span>
    </label>

    {mode === "PERSON" && <div className="person-stack">
      <label htmlFor="sender-person-search">Rechercher une Personne
        <input
          id="sender-person-search"
          type="search"
          autoComplete="off"
          value={query}
          onFocus={() => setOpen(true)}
          onChange={(event) => {
            setQuery(event.target.value);
            setSelectedPersonId("");
            setOpen(true);
          }}
          placeholder="Nom de la Personne"
        />
      </label>
      <input type="hidden" name="sender_person_id" value={selectedPersonId} />

      {open && <div className="person-list" role="listbox" aria-label="Personnes de la Structure">
        {filteredPeople.length === 0 ? (
          <p className="work-empty">Aucune Personne correspondante.</p>
        ) : filteredPeople.map((person) => (
          <button
            className="person-row"
            type="button"
            role="option"
            aria-selected={selectedPersonId === person.id}
            key={person.id}
            onMouseDown={(event) => event.preventDefault()}
            onClick={() => {
              setSelectedPersonId(person.id);
              setQuery(person.name);
              setOpen(false);
            }}
          >
            <span>
              <strong>{person.name}</strong>
              {person.role_label && <small>{person.role_label}</small>}
            </span>
          </button>
        ))}
      </div>}
    </div>}

    {mode === "UNREGISTERED" && <label htmlFor="external-author-label">Nom non enregistré
      <input
        id="external-author-label"
        name="external_author_label"
        type="text"
        maxLength={160}
        placeholder="Nom de l’expéditeur"
      />
    </label>}
  </fieldset>;
}
