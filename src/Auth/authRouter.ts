import express from "express";
import * as authController from "./authController";
const authRouter = express.Router();

authRouter.post("/register", authController.register);
authRouter.post("/login", authController.login); // login, create and get token

export default authRouter;
