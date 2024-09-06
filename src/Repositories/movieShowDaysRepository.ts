import db from "../db";

type getWithFilterReqQuery = {
  date?: string;
  date_lt?: string;
  date_gt?: string;
  has_instances_with_seats_left?: string;
  time_of_day_gt: string;
  time_of_day_lt: string;
};
type WhereClause = any;

export async function getById(id: string) {
  try {
    const movieShowDay = await db.movie_show_days.findFirst({
      where: { id: parseInt(id) },
    });
    return movieShowDay;
  } catch (error) {
    console.log(error);
    return false;
  }
}

export async function insert(movie_id: number, date: string) {
  const movieShowDay = await db.movie_show_days.create({
    data: { movie_id, date },
  });
  return movieShowDay;
}
export async function get_movie_show_day_details(movieShowDayId: string) {
  try {
    const rows =
      await db.$queryRaw`SELECT * FROM get_movie_show_day_details(${movieShowDayId})`;
    return rows;
  } catch (error) {
    console.log(error);
    return false;
  }
}
export async function get10(skip: number = 0) {
  const movieShowDays = await db.movie_show_days.findMany({ take: 10, skip });
  return movieShowDays;
}

export async function getWithFilter(reqQuery: getWithFilterReqQuery) {
  const where = {};

  helperFuncFilterByHasInstancesWithSeatsLeft(reqQuery, where);

  // handle date
  helperFuncFilterByDate(reqQuery, where);

  helperFunctionFilterByTimeOfDay(reqQuery, where);

  const rows = await db.movie_show_days.findMany({ where });
  return rows;
}

function helperFuncFilterByDate(
  reqQuery: getWithFilterReqQuery,
  where: WhereClause
) {
  // search by a specific date
  if (reqQuery.date) {
    query.values.push(reqQuery.date);
    query.text += ` date = ${query.values.length}`;
  }
  // search by a range
  else {
    if (reqQuery.date_gt) {
      query.values.push(reqQuery.date_gt);
      query.text += ` ${needsAnd(reqQuery, query) ? "AND " : ""}date > $${
        query.values.length
      } `;
    }
    if (reqQuery.date_lt) {
      query.values.push(reqQuery.date_lt);
      query.text += ` ${needsAnd(reqQuery, query) ? "AND " : ""}date < $${
        query.values.length
      } `;
    }
  }
}

function helperFuncFilterByHasInstancesWithSeatsLeft(
  reqQuery: getWithFilterReqQuery,
  where: WhereClause
) {
  if (
    typeof reqQuery.has_instances_with_seats_left === "undefined" ||
    reqQuery.has_instances_with_seats_left
  ) {
    where.has_instances_with_seats_left = true;
  }
}

function helperFunctionFilterByTimeOfDay(
  reqQuery: getWithFilterReqQuery,
  query: WhereClause
) {
  oh no 
  if (reqQuery.time_of_day_gt) {
    query.text += `${
      needsAnd(reqQuery, query) ? " AND" : ""
    } filter_show_days_by_the_times_of_their_instances_gt(movie_show_days.id,'${
      reqQuery.time_of_day_gt
    }')`;
  }
  if (reqQuery.time_of_day_lt) {
    query.text += `${
      needsAnd(reqQuery, query) ? " AND" : ""
    } filter_show_days_by_the_times_of_their_instances_lt(movie_show_days.id,'${
      reqQuery.time_of_day_lt
    }')`;
  }
}

function needsAnd(reqQuery: getWithFilterReqQuery, query: WhereClause) {
  if (query.values.length > 0) return true;
  if (
    typeof reqQuery.has_instances_with_seats_left === "undefined" ||
    reqQuery.has_instances_with_seats_left
  )
    return true;

  return false;
}
