// note: the next time you use stripe if it doesn’t work (webhook route doesn’t get hit up)
// It just means you have to like go to the terminal and do the log in stuff, then make stripe listen to the route.
//stripe listen --forward-to localhost:4000/purchase-tickets/webhook

// TODO :
// 1.FINISH EMAIL STUFF
// 2.ADD THEATER FUNCTIONALITY

// TODO: create indexes in the db for faster searches (one that comes off the top of my mind is a movie title index)

import express from "express";
import env from "dotenv";
import bodyParser from "body-parser";
import moviesRouter from "./routes/moviesRouter";
import movieShowDaysRouter from "./routes/movieShowDaysRouter";
import stripeRouter from "./Purchases/stripeRouter";
import authRouter from "./Auth/authRouter";
import { verifyTokenAndSetReqUser } from "./Auth/JWT";
import cronScheduler from "./cron/RemoveOldMovieShowDays";

env.config();

const app = express();

const port = process.env.PORT || 4001;

//Purchases
app.use("/purchase-tickets", stripeRouter);

//middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

//Register, Login (create and get token)
app.use("/auth", authRouter);

app.use("/movies", moviesRouter);
app.use("/movie-show-days", movieShowDaysRouter);

app.get("/temp", verifyTokenAndSetReqUser, (req, res) => {
  res.status(200).json({ user: req.user });
});

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
