import ReqHandler from "src/types/RequestHandler";
import { userRepository } from "src/Repositories/user.repository";
import RegisterAccountInput from "src/dto/RegisterAccountInput";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import LogIntoAccountInput from "src/dto/LogIntoAccountInput";
import * as JWT from "./JWT";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import { users as user } from "@prisma/client";
import comparePassword from "src/utils/comparePassword";
import * as HTTPResponses from "src/utils/HTTPResponses";

export const register: ReqHandler = async (req, res) => {
  try {
    const [errors, input] = await transformAndValidate(
      RegisterAccountInput,
      req.body
    );
    if (errors.length) return HTTPResponses.BadRequest(res, errors);
    const user: RegisterAccountInput = { ...input };

    const existingUser = await userRepository.getByFilter({
      email: user.email,
      phone_number: user.phone_number,
    });

    if (existingUser)
      return HTTPResponses.BadRequest(res, {
        message:
          "Email/Phone Number is already associated with another account",
      });

    // create user
    const createdUser = await userRepository.createUser(user);
    return HTTPResponses.SuccessResponse(res, { user: createdUser });
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};

export const login: ReqHandler = async (req, res) => {
  try {
    const input: { email: string; password: string } = { ...req.body };
    const errors = await validate(plainToInstance(LogIntoAccountInput, input));
    if (errors.length) return HTTPResponses.BadRequest(res, errors);

    const target = await userRepository.findByEmail(input.email);
    if (!target)
      return res
        .status(404)
        .json({ message: "User with this Email does not exist." });

    const user: user = { ...target };

    if (!(await comparePassword(input.password, user.password)))
      return HTTPResponses.Unauthorized(res, { message: "Incorrect password" });

    const token = JWT.createToken(user);
    return HTTPResponses.SuccessResponse(res, { token: `Bearer ${token}` });
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};
