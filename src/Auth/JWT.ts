import jwt from "jsonwebtoken";
import env from "dotenv";

import Middleware from "../types/Middleware";
import User from "src/types/User";

env.config();

const secretKey: string = process.env.JWT_SECRET_KEY ?? "";
export function createToken(data: any) {
  const payload = {
    data,
  };

  const token = jwt.sign(payload, secretKey, {
    expiresIn: "1h",
  });

  return token;
}

export const verifyTokenAndSetReqUser: Middleware = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (token === null || token === undefined) return res.sendStatus(401);

  jwt.verify(token, secretKey, (err, payload) => {
    console.log(payload);
    if (err) return res.sendStatus(403);
    if (typeof payload !== "string" && payload) {
      const user = payload.data as User;
      req.user = user;
    }

    next();
  });
};
