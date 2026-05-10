import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("dep-install-gate.sh", event, 20_000);
}
