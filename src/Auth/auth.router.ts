import express from "express";
import * as authController from "./auth.controller";
export const authRouter = express.Router();

authRouter.post("/register", authController.register);
authRouter.post("/login", authController.login); // login, create and get token
