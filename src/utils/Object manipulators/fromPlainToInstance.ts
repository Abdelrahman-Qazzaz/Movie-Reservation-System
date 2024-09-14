import { plainToInstance } from "class-transformer";

export async function fromPlainToInstance<T>(
  Class: new (...args: any[]) => T,
  instance: object
) {
  return plainToInstance(Class, instance);
}
