import test from "node:test";
import assert from "node:assert/strict";
import { parseProcessMessagePayload } from "../src/app/messages/[id]/traiter/payload.ts";

const messageId = "11111111-1111-4111-8111-111111111111";

function baseConsequencesFormData() {
  const formData = new FormData();
  formData.set("message_id", messageId);
  formData.set("resolution", "CONSEQUENCES_CREATED");
  return formData;
}

test("BORALOG-165 executable FormData carries one visible Information and one visible Task", () => {
  const formData = baseConsequencesFormData();
  formData.set("expected_information_count", "1");
  formData.set("expected_task_count", "1");
  formData.append("information_contents", "TEST INFORMATION");
  formData.append("task_contents", "TEST TASK");

  const payload = parseProcessMessagePayload(formData);

  assert.equal(payload.ok, true);
  if (!payload.ok) return;

  assert.deepEqual(payload.informationContents, ["TEST INFORMATION"]);
  assert.deepEqual(payload.taskContents, ["TEST TASK"]);
  assert.equal(payload.expectedInformationCount, 1);
  assert.equal(payload.expectedTaskCount, 1);
});

test("BORALOG-165 server payload guard rejects a silently lost Task draft", () => {
  const formData = baseConsequencesFormData();
  formData.set("expected_information_count", "1");
  formData.set("expected_task_count", "1");
  formData.append("information_contents", "TEST INFORMATION");

  const payload = parseProcessMessagePayload(formData);

  assert.deepEqual(payload, {
    ok: false,
    message: "Une conséquence affichée n’a pas été transmise. Réessayez sans quitter cette page.",
  });
});

test("BORALOG-165 server payload guard rejects a silently lost Information draft", () => {
  const formData = baseConsequencesFormData();
  formData.set("expected_information_count", "1");
  formData.set("expected_task_count", "1");
  formData.append("task_contents", "TEST TASK");

  const payload = parseProcessMessagePayload(formData);

  assert.equal(payload.ok, false);
});

test("BORALOG-165 no-follow-up payload explicitly expects zero consequences", () => {
  const formData = new FormData();
  formData.set("message_id", messageId);
  formData.set("resolution", "NO_FOLLOW_UP");
  formData.set("expected_information_count", "0");
  formData.set("expected_task_count", "0");

  const payload = parseProcessMessagePayload(formData);

  assert.equal(payload.ok, true);
  if (!payload.ok) return;
  assert.deepEqual(payload.informationContents, []);
  assert.deepEqual(payload.taskContents, []);
});
