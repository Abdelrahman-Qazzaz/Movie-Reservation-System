import express from "express";
import * as movieShowDaysController from "../controllers/movieShowDaysController";
import checkAdmin from "src/middleware/CheckAdmin";
``;
const movieShowDaysRouter = express.Router();

// optional Query Parameters: date, date_gt, date_lt time_of_day_gt has_instances_with_seats_left (default: TRUE)
movieShowDaysRouter.get("/", movieShowDaysController.get);
movieShowDaysRouter.post("/", /*checkAdmin*/, movieShowDaysController.add);

movieShowDaysRouter.get("/:id", movieShowDaysController.getById);

movieShowDaysRouter.get("/:id/details", movieShowDaysController.getDetails);

export default movieShowDaysRouter;
