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

  async createUser(user: user) {
    return await db.users.create({ data: user });
  }

  async findByEmail(email: string) {
    return await db.users.findFirst({ where: { email } });
  }
}

const userRepository = new UserRepository();
export default userRepository;
