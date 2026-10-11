export type AddMessageNoteState =
  | { status: "idle"; message: ""; values: { content: string } }
  | { status: "error"; message: string; values: { content: string } }
  | { status: "success"; message: string; values: { content: string } };

export type MessageStatusState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string }
  | { status: "success"; message: string };

export const initialAddMessageNoteState: AddMessageNoteState = {
  status: "idle",
  message: "",
  values: { content: "" },
};

export const initialMessageStatusState: MessageStatusState = {
  status: "idle",
  message: "",
};
