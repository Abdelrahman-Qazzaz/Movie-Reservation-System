import { plainToInstance } from "class-transformer";
import { validate, ValidationError } from "class-validator";

async function transformAndValidate(
  Class: any,
  input: any
): Promise<[errors: ValidationError[], transformedInput: any]> {
  const transformedInput = plainToInstance(Class, input);
  const errors = await validate(transformedInput);
  return [errors, transformedInput];
}

export default transformAndValidate;
