export type CreateMessageValues = { content: string; projectId: string; eventId: string };

export type CreateMessageState =
  | { status: "idle"; message: ""; values: CreateMessageValues }
  | { status: "error"; message: string; values: CreateMessageValues }
  | { status: "success"; message: string; values: CreateMessageValues };

export const initialCreateMessageState: CreateMessageState = {
  status: "idle",
  message: "",
  values: { content: "", projectId: "", eventId: "" },
};
