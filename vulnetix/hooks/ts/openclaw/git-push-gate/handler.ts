import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("git-push-gate.sh", event, 30_000);
}
