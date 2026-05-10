import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("prompt-router.sh", event, 10_000);
}
