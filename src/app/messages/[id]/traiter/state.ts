export type ProcessMessageState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string };

export const initialProcessMessageState: ProcessMessageState = {
  status: "idle",
  message: "",
};
