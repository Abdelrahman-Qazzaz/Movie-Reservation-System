import "reflect-metadata";
import express from "express";
import env from "dotenv";
import bodyParser from "body-parser";
import { stripeRouter } from "./Purchases/stripe.router";
import { cronRemoveOldMSDs } from "./cron/cron.removeOldMSDs";
import { authRouter } from "./Auth/auth.router";
import { mRouter } from "./routes/m.router";
import { msdRouter } from "./routes/msd.router";
import { msdiRouter } from "./routes/msdi.router";

cronRemoveOldMSDs();
env.config();

const app = express();

const port = process.env.PORT || 4001;

//Purchases (make sure to keep this above middleware)
app.use("/purchase-tickets", stripeRouter);

//middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

app.use("/auth", authRouter);
app.use("/m", mRouter);
app.use("/msd", msdRouter);
app.use("/msdi", msdiRouter);

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
