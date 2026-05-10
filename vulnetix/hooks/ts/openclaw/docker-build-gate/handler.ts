import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("docker-build-gate.sh", event, 30_000);
}
