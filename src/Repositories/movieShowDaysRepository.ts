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
export async function get10(skip: number = 0) {
  return await db.movie_show_days.findMany({ take: 10, skip });
}

export async function insert(movie_id: number, date: string) {
  return await db.movie_show_days.create({ data: { movie_id, date } });
}

export async function get_movie_show_day_details(movieShowDayId: string) {
  try {
    return await db.$queryRaw`SELECT * FROM get_movie_show_day_details(${movieShowDayId})`;
  } catch (error) {
    console.log(error);
    return false;
  }
}

export async function getWithFilter(reqQuery: getWithFilterReqQuery) {
  // either returns filtered movie show days,
  // or all movie show days (if no time filters were used)

  let movieShowDays: MovieShowDay[] | null = await helper.filterByTimeOfDay(
    reqQuery
  );
  console.log(movieShowDays);
  // movieShowDays = await helper.filterByDate(reqQuery, movieShowDays);

  // // handle date
  // movieShowDays = await helper.filterByDate(reqQuery, where);

  // await db.movie_show_days.findMany({ where });

  // return movieShowDays;
}
