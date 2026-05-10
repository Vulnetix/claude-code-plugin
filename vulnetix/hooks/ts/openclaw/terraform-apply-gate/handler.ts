import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("terraform-apply-gate.sh", event, 30_000);
}
