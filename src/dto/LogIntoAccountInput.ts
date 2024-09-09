import { Transform } from "class-transformer";
import { IsEmail, IsStrongPassword } from "class-validator";

class LogIntoAccountInput {
  @IsEmail()
  @Transform(({ value }) => value.toLowerCase(), { toClassOnly: true })
  email: string;

  @IsStrongPassword()
  password: string;

  constructor(email: string, password: string) {
    this.email = email;
    this.password = password;
  }
}
export default LogIntoAccountInput;
