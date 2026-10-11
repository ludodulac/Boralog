export type CreateDateValues = { date: string; time: string; city: string; venue: string };
export type CreateDateState =
  | { status: "idle"; message: ""; values: CreateDateValues }
  | { status: "error"; message: string; values: CreateDateValues }
  | { status: "success"; message: string; values: CreateDateValues };

export const initialCreateDateState: CreateDateState = { status: "idle", message: "", values: { date: "", time: "", city: "", venue: "" } };
