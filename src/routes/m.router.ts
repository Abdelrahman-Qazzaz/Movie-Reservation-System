import express from "express";
import * as mController from "../controllers/m.controller";

export const mRouter = express.Router();

//root (/movies)
// optional Query Parameters: ?page=1 (1 page = 10 movies)
// languages
// adult (boolean, default: true)
//release date
// release_date_gt
// release_date_lt
// sort_by_popularity (boolean, default: false)
mRouter.get("/", mController.get);
mRouter.get("/:title", mController.getByTitle);
