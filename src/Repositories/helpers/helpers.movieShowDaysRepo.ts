import db from "src/db";
import MsdFilterQuery from "src/dto/Search by filter/filter.movieShowDays.dto";
import { movie_show_days as movie_show_day } from "@prisma/client";

export async function filterByTimeOfDay(reqQuery: MsdFilterQuery) {
  if (reqQuery.time_of_day_gt && reqQuery.time_of_day_lt) {
    const gt: movie_show_day[] =
      await db.$queryRaw`SELECT * FROM filter_show_days_by_the_times_of_their_instances_gt(${reqQuery.time_of_day_gt});`;
    const lt: movie_show_day[] =
      await db.$queryRaw`SELECT * FROM filter_show_days_by_the_times_of_their_instances_lt(${reqQuery.time_of_day_lt});`;
    if (gt.length && lt.length)
      return gt.filter((movieShowDay) =>
        lt.some((ltItem) => ltItem.id === movieShowDay.id)
      );
    if (gt.length) return gt;
    if (lt.length) return lt;
    return null;
  }

  if (reqQuery.time_of_day_gt)
    return await db.$queryRaw<
      movie_show_day[]
    >`SELECT * FROM filter_show_days_by_the_times_of_their_instances_gt(${reqQuery.time_of_day_gt});`;

  if (reqQuery.time_of_day_lt)
    return await db.$queryRaw<
      movie_show_day[]
    >`SELECT * FROM filter_show_days_by_the_times_of_their_instances_lt(${reqQuery.time_of_day_lt});`;

  return await db.movie_show_days.findMany(); // return all movie show days
}

export function filterByDate(
  reqQuery: MsdFilterQuery,
  movieShowDays: movie_show_day[] | null
) {
  if (!movieShowDays) return null;

  // search by a specific date
  if (reqQuery.date) {
    movieShowDays = movieShowDays.filter(
      (movieShowDay) => movieShowDay.date === new Date(reqQuery.date!)
    );
  }
  // search by a range
  else {
    if (reqQuery.date_gt) {
      movieShowDays = movieShowDays.filter(
        (movieShowDay) => movieShowDay.date > new Date(reqQuery.date_gt!)
      );
    }
    if (reqQuery.date_lt) {
      movieShowDays = movieShowDays.filter(
        (movieShowDay) => movieShowDay.date < new Date(reqQuery.date_lt!)
      );
    }
  }
  return movieShowDays;
}

export function filterByHasInstancesWithSeatsLeft(
  reqQuery: MsdFilterQuery,
  movieShowDays: movie_show_day[] | null
) {
  if (!movieShowDays) return null;
  if (reqQuery.has_instances_with_seats_left) {
    movieShowDays.filter(
      (movieShowDay) => movieShowDay.has_instances_with_seats_left
    );
  }
  if (reqQuery.has_instances_with_seats_left) {
    movieShowDays.filter(
      (movieShowDay) => !movieShowDay.has_instances_with_seats_left
    );
  }
  return movieShowDays;
}
