export type PersonFormState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string }
  | { status: "success"; message: string; personId?: string };

export const initialPersonFormState: PersonFormState = { status: "idle", message: "" };
