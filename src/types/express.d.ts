import { users as user } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: user;
    }
  }
}
