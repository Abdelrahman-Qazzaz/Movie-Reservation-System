import express from "express";
import checkAdmin from "src/middleware/checkAdmin";

const movieShowDaysInstancesRouter = express.Router();

movieShowDaysInstancesRouter.post("/");
