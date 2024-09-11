import express from "express";
import checkAdmin from "src/middleware/checkAdmin";
import * as msdiController from "../controllers/msdi.controller";

export const msdiRouter = express.Router();

msdiRouter.post("/", checkAdmin, msdiController.create);
msdiRouter.get("/", msdiController.get);
