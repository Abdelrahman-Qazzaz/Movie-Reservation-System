import express from "express";
import * as moviesController from "../controllers/moviesController";

const moviesRouter = express.Router();

//root (/movies)
// optional Query Parameters: ?page=1 (1 page = 10 movies)
// languages
// adult (boolean, default: true)
//release date
// release_date_gt
// release_date_lt
// sort_by_popularity (boolean, default: false)
moviesRouter.get("/", moviesController.get);

moviesRouter.get("/:title", moviesController.getByTitle);

export default moviesRouter;
