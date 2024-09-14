import express from "express";
import * as msdController from "../controllers/msd.controller";
import checkAdmin from "src/middleware/checkAdmin";
export const msdRouter = express.Router();

// optional Query Parameters: date, date_gt, date_lt time_of_day_gt time_of_day_lt has_instances_with_seats_left (default: TRUE)
msdRouter.get("/", msdController.get);
// msdRouter.get("/:id", msdController.getById);

// msdRouter.get("/:id/details", msdController.getDetails);

// msdRouter.post("/", checkAdmin, msdController.add);
