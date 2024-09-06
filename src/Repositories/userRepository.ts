import User from "src/types/User";
import db from "../db";

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
    try {
      const user = await db.users.findFirst({ where: filter });
      return user;
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async createUser(user: User) {
    try {
      const createdUser = await db.users.create({ data: user });
      return createdUser;
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async findByEmail(email: string) {
    try {
      const user = await db.users.findFirst({ where: { email } });
      return user; // no result? returns null
    } catch (error) {
      console.log(error);
      return false;
    }
  }
}

const userRepository = new UserRepository();
export default userRepository;
