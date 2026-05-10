import { runHook } from "../../run-hook";

export default async function handler(event: any) {
  runHook("capabilities-detect.sh", event, 15_000);
}
