import Email from "./Email";
import React from "react";
import { Resend } from "resend";
import db from "../../db";
import env from "dotenv";
env.config({ path: "../../.env" });

const resend = new Resend(process.env.RESEND_API_KEY);

import ReactDOMServer from "react-dom/server";

async function sendEmail(customerDetails: any, ticket: any) {
  try {
    const rows = await db.query("SELECT * FROM get_ticket_details($1)", [
      ticket.description.split(":")[1].trim(),
    ]);

    ticket = { id: rows[0].ticket_id, seat_position: rows[0].seat_position };
    const movie = {
      movie_title: rows[0].movie_title,
      image_url: rows[0].movie_poster,
      imageonClickLocationHref: rows[0].movie_poster,
    };

    const dateAndTime = {
      date: rows[0].show_date,
      time: rows[0].show_start_time,
    };

    const emailHtml = ReactDOMServer.renderToStaticMarkup(
      React.createElement(Email, {
        customer_name: customerDetails.name,
        ticket: { ...ticket },
        movie: { ...movie },
        dateAndTime: { ...dateAndTime },
      })
    );

    const { data, error } = await resend.emails.send({
      from: "Acme <onboarding@resend.dev>",
      to: [process.env.YOUR_EMAIL || ""],
      subject: "Thank you",
      html: emailHtml,
    });
    if (error) {
      console.log(error);
    }
    console.log(data);
  } catch (error) {
    console.log(error);
  }
}

export default sendEmail;
