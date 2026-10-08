import test from "node:test";
import assert from "node:assert/strict";
import { addMessageNote, setMessageStatus } from "../src/app/messages/[id]/actions.ts";
import { initialAddMessageNoteState, initialMessageStatusState } from "../src/app/messages/[id]/state.ts";

const messageId = "11111111-1111-4111-8111-111111111111";

function makeTestDependencies(error: { message: string } | null = null) {
  const calls: Array<{ name: string; args: Record<string, unknown> }> = [];
  const paths: string[] = [];
  return {
    calls,
    paths,
    dependencies: {
      client: {
        async rpc(name: string, args: Record<string, unknown>) {
          calls.push({ name, args });
          return { error };
        },
      },
      revalidate(path: string) {
        paths.push(path);
      },
    },
  };
}

test("BORALOG-165R Note action calls canonical RPC", async () => {
  const fixture = makeTestDependencies();
  const data = new FormData();
  data.set("message_id", messageId);
  data.set("content", "  NOTE TEST 165R  ");

  const result = await addMessageNote(initialAddMessageNoteState, data, fixture.dependencies);

  assert.equal(result.status, "success");
  assert.deepEqual(fixture.calls, [{
    name: "boralog_add_message_note",
    args: { p_message_id: messageId, p_content: "NOTE TEST 165R" },
  }]);
  assert.deepEqual(fixture.paths, ["/messages/" + messageId, "/messages"]);
});

test("BORALOG-165R Note action preserves content after RPC error", async () => {
  const fixture = makeTestDependencies({ message: "rejected" });
  const data = new FormData();
  data.set("message_id", messageId);
  data.set("content", "NOTE À CONSERVER");

  const result = await addMessageNote(initialAddMessageNoteState, data, fixture.dependencies);

  assert.equal(result.status, "error");
  assert.deepEqual(result.values, { content: "NOTE À CONSERVER" });
  assert.equal(fixture.paths.length, 0);
});

test("BORALOG-165R Note action rejects blank content before RPC", async () => {
  const fixture = makeTestDependencies();
  const data = new FormData();
  data.set("message_id", messageId);
  data.set("content", "   ");

  const result = await addMessageNote(initialAddMessageNoteState, data, fixture.dependencies);

  assert.equal(result.status, "error");
  assert.equal(fixture.calls.length, 0);
});

test("BORALOG-165R status action calls both canonical transitions", async () => {
  const fixture = makeTestDependencies();

  const processedData = new FormData();
  processedData.set("message_id", messageId);
  processedData.set("status", "PROCESSED");
  const processed = await setMessageStatus(initialMessageStatusState, processedData, fixture.dependencies);

  const reopenedData = new FormData();
  reopenedData.set("message_id", messageId);
  reopenedData.set("status", "TO_PROCESS");
  const reopened = await setMessageStatus(initialMessageStatusState, reopenedData, fixture.dependencies);

  assert.equal(processed.status, "success");
  assert.equal(reopened.status, "success");
  assert.deepEqual(fixture.calls.map((call) => call.args), [
    { p_message_id: messageId, p_status: "PROCESSED" },
    { p_message_id: messageId, p_status: "TO_PROCESS" },
  ]);
});
