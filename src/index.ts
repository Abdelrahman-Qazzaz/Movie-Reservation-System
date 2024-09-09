import express from "express";
import env from "dotenv";
import bodyParser from "body-parser";
import movieShowDaysRouter from "./routes/movieShowDaysRouter";
import stripeRouter from "./Purchases/stripeRouter";
import cronScheduler from "./cron/RemoveOldMovieShowDays";
import authRouter from "./Auth/authRouter";

cronScheduler();
env.config();

const app = express();

const port = process.env.PORT || 4001;

//Purchases (make sure to keep this above middleware)
app.use("/purchase-tickets", stripeRouter);

//middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

app.use("/auth", authRouter);
app.use("/movie-show-days", movieShowDaysRouter);
// app.use("/movies", moviesRouter);

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
