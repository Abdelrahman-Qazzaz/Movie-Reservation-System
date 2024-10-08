import express from "express";

import * as stripeController from "./stripe.controller";
export const stripeRouter = express.Router();

stripeRouter.get("/:ticket_id", stripeController.createCheckoutSession);
stripeRouter.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  stripeController.webHook
);
