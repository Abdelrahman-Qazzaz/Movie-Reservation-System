import { movie_show_days } from "@prisma/client";
import db from "src/db";
import { getWithFilterReqQuery } from "src/types/Movie Show Days/filter.movieShowDays";
import MovieShowDay from "src/types/Movie Show Days/movieShowDay";

export async function filterByTimeOfDay(reqQuery: getWithFilterReqQuery) {
  if (reqQuery.time_of_day_gt && reqQuery.time_of_day_lt) {
    const gt: MovieShowDay[] =
      await db.$queryRaw`SELECT * FROM filter_show_days_by_the_times_of_their_instances_gt(${reqQuery.time_of_day_gt});`;
    const lt: MovieShowDay[] =
      await db.$queryRaw`SELECT * FROM filter_show_days_by_the_times_of_their_instances_lt(${reqQuery.time_of_day_lt});`;
    if (gt.length && lt.length)
      return gt.filter((movieShowDay) => lt.includes(movieShowDay));
    if (gt.length) return gt;
    if (lt.length) return lt;
    return null;
  }

  if (reqQuery.time_of_day_gt)
    return await db.$queryRaw<
      MovieShowDay[]
    >`SELECT * FROM filter_show_days_by_the_times_of_their_instances_gt(${reqQuery.time_of_day_gt});`;

  if (reqQuery.time_of_day_lt)
    return await db.$queryRaw<
      MovieShowDay[]
    >`SELECT * FROM filter_show_days_by_the_times_of_their_instances_lt(${reqQuery.time_of_day_lt});`;

  return await db.movie_show_days.findMany(); // return all movie show days
}

export function filterByDate(
  reqQuery: getWithFilterReqQuery,
  movieShowDays: MovieShowDay[]
) {
  // search by a specific date
  if (reqQuery.date) {
    return movieShowDays.filter(
      (movieShowDay) => movieShowDay.date === new Date(reqQuery.date!)
      // left here
    );
  }
  // search by a range
  else {
    if (reqQuery.date_gt) {
      // where.date = { gt: reqQuery.date_gt };
    }
    if (reqQuery.date_lt) {
      // where.date = { lt: reqQuery.date_lt };
    }
  }
}

// export function filterByHasInstancesWithSeatsLeft(movieShowDays) {
//   if (
//     typeof reqQuery.has_instances_with_seats_left === "undefined" ||
//     reqQuery.has_instances_with_seats_left
//   ) {
//     where.has_instances_with_seats_left = true;
//   }
// }
