import {
  IsString,
  IsEmail,
  IsNotEmpty,
  Length,
  IsPhoneNumber,
} from "class-validator";

class RegisterAccountInput {
  @IsString()
  @IsNotEmpty()
  @Length(3, 20)
  full_name: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @Length(6, 50)
  password: string;

  @IsNotEmpty()
  @IsPhoneNumber()
  phone_number: string;

  constructor(
    full_name: string,
    email: string,
    password: string,
    phone_number: string
  ) {
    this.full_name = full_name;
    this.email = email;
    this.password = password;
    this.phone_number = phone_number;
  }
}
export default RegisterAccountInput;
