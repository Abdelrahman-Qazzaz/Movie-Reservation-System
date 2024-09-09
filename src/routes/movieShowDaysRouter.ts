import express from "express";
import * as movieShowDaysController from "../controllers/movieShowDaysController";
import checkAdmin from "src/middleware/checkAdmin";
``;
const movieShowDaysRouter = express.Router();

// optional Query Parameters: date, date_gt, date_lt time_of_day_gt time_of_day_lt has_instances_with_seats_left (default: TRUE)
movieShowDaysRouter.get("/:id", movieShowDaysController.getById);
movieShowDaysRouter.get("/", movieShowDaysController.get);

movieShowDaysRouter.post("/", checkAdmin, movieShowDaysController.add);

movieShowDaysRouter.get("/:id/details", movieShowDaysController.getDetails);

export default movieShowDaysRouter;
