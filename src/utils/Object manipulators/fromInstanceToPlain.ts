import { instanceToPlain } from "class-transformer";

export function fromInstanceToPlain(instance: unknown): object {
  return instanceToPlain(instance);
}
