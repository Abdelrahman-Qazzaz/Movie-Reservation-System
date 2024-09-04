import User from "src/types/User";
import db from "../db";
import { query } from "express";

class UserRepository {
  async getById(userID: number) {
    try {
      const { rows } = await db.query("SELECT * FROM users WHERE id = $1", [
        userID,
      ]);
      return rows[0];
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async getByFilter(filter: { email?: string; phone_number?: string }) {
    const { email, phone_number } = filter;

    const values = [];
    if (email) values.push(email);
    if (phone_number) values.push(phone_number);

    const query = `SELECT * FROM users WHERE ${email ? `email = $1` : ""} ${
      values.length ? "OR" : ""
    }  ${phone_number ? `phone_number = $2` : ""}`;

    try {
      console.log(query, values);
      const { rows } = await db.query(query, values);
      return rows;
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async createUser(user: User) {
    try {
      const { rows } = await db.query(
        "INSERT INTO users (full_name,phone_number,email,password) VALUES($1,$2,$3,$4) RETURNING * ",
        [user.full_name, user.phone_number, user.email, user.password]
      );
      return rows[0];
    } catch (error) {
      console.log(error);
      return false;
    }
  }

  async findByEmail(email: string) {
    const { rows } = await db.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    return rows.length ? rows[0] : false;
  }
}

const userRepository = new UserRepository();
export default userRepository;
