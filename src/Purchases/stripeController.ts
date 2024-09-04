import env from "dotenv";
env.config();
import Stripe from "stripe";
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY ?? "");
import db from "../db";
import sendEmail from "../utils/Email/sendEmail";
import ReqHandler from "src/types/RequestHandler";

export const createCheckoutSession: ReqHandler = async (req, res) => {
  const { rows } = await db.query(
    `SELECT * FROM get_ticket_details(${req.params.ticket_id})`
  );
  console.log(rows);
  if (rows[0].ticket_reserved_by_user_id)
    return res
      .status(400)
      .json({ message: "Ticket has already been reserved." });
  const items = [rows[0]];

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ["card"],
    line_items: items.map((item) => ({
      price_data: {
        currency: "usd",
        unit_amount: 1000, // price in cents, equates to $10.
        product_data: {
          name: `Ticket Id: ${item.ticket_id}`,
          description: `Seat position ${item.seat_position} Movie title: ${
            item.movie_title
          }
          Show Date: ${item.show_date.toLocaleString("default", {
            month: "long",
          })} ${item.show_date.getDate()} ${item.show_date.getFullYear()}
          Time: ${item.show_start_time}`,
          images: [item.movie_poster],
        },
      },
      quantity: 1,
    })),
    mode: "payment",
    success_url: `${process.env.CLIENTURL}/purchase-tickets/success`,
    cancel_url: `${process.env.CLIENTURL}/purchase-tickets/cancel`,
  });

  res.json({ sessionURL: session.url });
};
const date = new Date();

// executes on events
export const webHook: ReqHandler = async (req, res) => {
  const payload = req.body;
  const sig = req.headers["stripe-signature"];

  let event;

  try {
    event = stripe.webhooks.constructEvent(
      payload,
      sig!,
      process.env.STRIPE_END_POINT_SECRET!
    );
  } catch (error: any) {
    console.error(error);
    return res.status(400).send(`Webhook Error: ${error.message}`);
  }

  if (
    event.type === "checkout.session.completed" ||
    event.type === "checkout.session.async_payment_succeeded"
  ) {
    fulfillCheckout(event.data.object.id);
  } else {
    console.log(event.type);
  }

  res.status(200).end();
};

async function fulfillCheckout(sessionId: string) {
  const checkoutSession = await stripe.checkout.sessions.retrieve(sessionId, {
    expand: ["line_items"],
  });

  if (checkoutSession.metadata?.fulfilled) {
    console.log("Checkout Session already fulfilled");
    return;
  }

  const success = await fulfillOrder(
    checkoutSession.customer_details,
    checkoutSession.line_items?.data[0]
  );

  if (success) {
    await stripe.checkout.sessions.update(sessionId, {
      metadata: {
        fulfilled: 1,
      },
    });
    await sendEmail(
      checkoutSession.customer_details,
      checkoutSession.line_items?.data[0]
    );
  }
}

async function fulfillOrder(
  checkoutSessionCustomerDetails: any,
  checkoutSessionItem: any
) {
  const customer = {
    name: checkoutSessionCustomerDetails.name,
    email: checkoutSessionCustomerDetails.email,
  };

  const purchaseDetails = {
    ticket_id: parseInt(checkoutSessionItem.description.split(":")[1].trim()),
    amount_total: checkoutSessionItem.amount_total,
    currency: checkoutSessionItem.currency,
  };
  try {
    await db.query(`SELECT log_transaction($1,$2)`, [
      customer.email,
      purchaseDetails,
    ]);
    return true;
  } catch (error) {
    console.error(error);
    return false;
  }
}
