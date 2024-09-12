import { instanceToPlain, plainToInstance } from "class-transformer";
import { validate, ValidationError } from "class-validator";

async function transformAndValidate<T>(
  Class: new (...args: any[]) => T,
  input: any
): Promise<[errors: ValidationError[], transformedInput: T]> {
  const transformedInput = plainToInstance(Class, input);
  const errors = await validate(transformedInput as object);
  return [errors, transformedInput];
}

export default transformAndValidate;
