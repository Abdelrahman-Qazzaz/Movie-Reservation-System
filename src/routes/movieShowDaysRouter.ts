import express from "express";
import * as movieShowDaysController from "../controllers/movieShowDaysController";
import checkAdmin from "src/middleware/checkAdmin";
const movieShowDaysRouter = express.Router();

// optional Query Parameters: date, date_gt, date_lt time_of_day_gt time_of_day_lt has_instances_with_seats_left (default: TRUE)
movieShowDaysRouter.get("/", movieShowDaysController.get);
movieShowDaysRouter.get("/:id", movieShowDaysController.getById);

movieShowDaysRouter.get("/:id/details", movieShowDaysController.getDetails);

movieShowDaysRouter.post("/", checkAdmin, movieShowDaysController.add);

export default movieShowDaysRouter;
