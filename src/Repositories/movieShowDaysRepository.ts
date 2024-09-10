import { movie_show_days as movie_show_day } from "@prisma/client";
import db from "../db";
import * as helper from "./helpers/helpers.movieShowDaysRepo";
import MsdFilterQuery from "src/dto/Search by filter/filter.movieShowDays.dto";

export async function getById(id: number) {
  try {
    return await db.movie_show_days.findFirst({
      where: { id },
    });
  } catch (error) {
    console.log(error);
    return false;
  }
}
export async function getAll() {
  return await db.movie_show_days.findMany();
}
export async function get10(skip: number = 0) {
  return await db.movie_show_days.findMany({ take: 10, skip });
}

export async function insert(input: { movie_id: number; date: Date }) {
  return await db.movie_show_days.create({ data: input });
}

export async function get_movie_show_day_details(movieShowDayId: number) {
  try {
    return await db.$queryRaw`SELECT * FROM get_movie_show_day_details(${movieShowDayId}::integer)`;
  } catch (error) {
    console.log(error);
    return false;
  }
}

export async function getWithFilter(
  reqQuery: MsdFilterQuery,
  offset: number = 0,
  limit: number = 0
) {
  let movieShowDays: movie_show_day[] | null = null;
  if (reqQuery.time_of_day_gt || reqQuery.time_of_day_lt) {
    // filter by time of instances
    movieShowDays = await helper.filterByTimeOfDay(reqQuery);
  } else {
    // get all
    movieShowDays = await db.movie_show_days.findMany();
  }

  //  date
  movieShowDays = helper.filterByDate(reqQuery, movieShowDays);

  movieShowDays = helper.filterByHasInstancesWithSeatsLeft(
    reqQuery,
    movieShowDays
  );

  return movieShowDays?.slice(offset, limit);
}
