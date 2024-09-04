import env from "dotenv";
import Middleware from "../types/Middleware";
env.config();
const checkAdmin: Middleware = (req, res, next) => {
  if (req.headers.adminkey !== process.env.ADMINKEY) return res.sendStatus(401);
  else next();
};

export default checkAdmin;
