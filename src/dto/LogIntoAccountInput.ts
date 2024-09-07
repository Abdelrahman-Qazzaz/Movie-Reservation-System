import { IsString, IsEmail, IsNotEmpty, Length } from "class-validator";

class LogIntoAccountInput {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @Length(6, 50)
  password: string;

  constructor(email: string, password: string) {
    this.email = email;
    this.password = password;
  }
}
export default LogIntoAccountInput;
