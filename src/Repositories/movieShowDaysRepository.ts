import MovieShowDay from "src/types/Movie Show Days/movieShowDay";
import db from "../db";

import * as helper from "./helpers/helpers.movieShowDaysRepo";
import { getWithFilterReqQuery } from "src/types/Movie Show Days/filter.movieShowDays";

export async function getById(id: string) {
  try {
    return await db.movie_show_days.findFirst({
      where: { id: parseInt(id) },
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

export async function insert(movie_id: number, date: string) {
  return await db.movie_show_days.create({ data: { movie_id, date } });
}

export async function get_movie_show_day_details(movieShowDayId: string) {
  try {
    return await db.$queryRaw`SELECT * FROM get_movie_show_day_details(${movieShowDayId}::integer)`;
  } catch (error) {
    console.log(error);
    return false;
  }
}

export async function getWithFilter(
  reqQuery: getWithFilterReqQuery,
  offset: number = 0,
  limit: number = 0
) {
  let movieShowDays: MovieShowDay[] | null = null;
  if (reqQuery.time_of_day_gt || reqQuery.time_of_day_lt) {
    // filter by time of instances
    movieShowDays = await helper.filterByTimeOfDay(reqQuery);
  } else {
    // get all
    movieShowDays = await db.movie_show_days.findMany();
  }

  //  date
  movieShowDays = await helper.filterByDate(reqQuery, movieShowDays);

  movieShowDays = await helper.filterByHasInstancesWithSeatsLeft(
    reqQuery,
    movieShowDays
  );

  return movieShowDays?.slice(offset, limit);
}
