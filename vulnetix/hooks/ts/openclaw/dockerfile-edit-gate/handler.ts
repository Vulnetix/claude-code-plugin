import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("dockerfile-edit-gate.sh", event, 10_000);
}
