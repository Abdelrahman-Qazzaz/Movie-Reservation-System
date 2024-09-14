import {
  IsString,
  IsNotEmpty,
  Length,
  Contains,
  IsMobilePhone,
} from "class-validator";
import LogIntoAccountInput from "./LogIntoAccountInput.dto";

class RegisterAccountInput extends LogIntoAccountInput {
  @IsString()
  @IsNotEmpty()
  @Length(5, 20)
  @Contains(" ", { message: "Full Name must contain a space." })
  full_name: string;

  @IsMobilePhone()
  phone_number: string;
}
export default RegisterAccountInput;
