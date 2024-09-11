import express from "express";
import checkAdmin from "src/middleware/checkAdmin";
import * as movieShowDaysInstancesController from "../controllers/movieShowDaysInstancesController";

const movieShowDaysInstancesRouter = express.Router();

movieShowDaysInstancesRouter.post(
  "/",
  checkAdmin,
  movieShowDaysInstancesController.create
);
movieShowDaysInstancesRouter.get("/", movieShowDaysInstancesController.get);

export default movieShowDaysInstancesRouter;
