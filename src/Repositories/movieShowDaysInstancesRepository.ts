import { movie_show_days_instances as movie_show_days_instance } from "@prisma/client";
import db from "../db";
import { AdminAddMovieShowDayInstanceInput } from "src/dto/AdminAddMovieShowDayInstanceInput";

export async function add(data: AdminAddMovieShowDayInstanceInput) {
  return await db.movie_show_days_instances.create({
    data: { ...data, has_seats_left: false },
  });
}

export async function get() {
  return await db.movie_show_days_instances.findMany({
    include: { movie_show_days: true },
  });
}
