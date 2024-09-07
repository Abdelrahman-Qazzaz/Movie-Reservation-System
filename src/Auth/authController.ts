import ReqHandler from "src/types/RequestHandler";
import User from "src/types/User";

import userRepository from "src/Repositories/userRepository";
import RegisterAccountInput from "src/dto/RegisterAccountInput";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import LogIntoAccountInput from "src/dto/LogIntoAccountInput";
import * as JWT from "./JWT";

export const register: ReqHandler = async (req, res) => {
  try {
    const input = { ...req.body };
    const errors = await validate(plainToInstance(RegisterAccountInput, input));
    if (errors.length) return res.status(400).json(errors);

    req.body.email = req.body.email.toLowerCase();

    const user: User = { ...input };
    const results: any[] | false = await userRepository.getByFilter({
      email: user.email,
      phone_number: user.phone_number,
    });
    if (!results) return res.sendStatus(500); // internal server error

    const userExists = results.length ? true : false;
    if (userExists)
      return res.status(400).json({
        message:
          "Email/Phone Number is already associated with another account",
      });

    // create user
    const createdUser: User = await userRepository.createUser(user);
    res.sendStatus(201).json({ user: createdUser });
  } catch (error) {
    console.log(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const login: ReqHandler = async (req, res) => {
  try {
    const input: { email: string; password: string } = { ...req.body };
    const errors = await validate(plainToInstance(LogIntoAccountInput, input));
    if (errors.length) return res.status(400).json(errors);

    const target = await userRepository.findByEmail(input.email);
    if (!target)
      return res
        .status(404)
        .json({ message: "User with this Email does not exist." });

    const user: User = { ...target };
    const token = JWT.createToken(user);
    res.status(200).json({ token: `Bearer ${token}` });
  } catch (error) {
    console.log(error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
