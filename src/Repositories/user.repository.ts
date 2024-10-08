import RegisterAccountInput from "src/dto/RegisterAccountInput";
import db from "../db";
import { users as user } from "@prisma/client";
class UserRepository {
  async getById(userID: number) {
    try {
      const targetUser = await db.users.findFirst({
        where: {
          id: userID,
        },
      });
      return targetUser;
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async getByFilter(filter: { email?: string; phone_number?: string }) {
    return await db.users.findFirst({ where: filter });
  }

  async createUser(user: RegisterAccountInput) {
    return await db.users.create({ data: user });
  }

  async findByEmail(email: string) {
    return await db.users.findFirst({ where: { email } });
  }
}

export const userRepository = new UserRepository();
