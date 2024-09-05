import db from "../db";

type getWithFilterReqQuery = {
  date?: string;
  date_lt?: string;
  date_gt?: string;
  has_instances_with_seats_left?: string;
  time_of_day_gt: string;
  time_of_day_lt: string;
};
type DBquery = {
  text: string;
  values: any[];
};

export async function getById(id: string) {
  const { rows } = await db.query(
    "SELECT * FROM movie_show_days WHERE id = $1",
    [id]
  );
  return rows[0];
}

export async function insert(movie_id: number, date: string) {
  const results = await db.query(
    "INSERT INTO movie_show_days (movie_id,date) VALUES($1,$2)",
    [movie_id, date]
  );
  console.log(results);
  return results.rows[0];
}
export async function get_movie_show_day_details(movieShowDayId: string) {
  const { rows } = await db.query(
    `SELECT * FROM get_movie_show_day_details($1)`,
    [movieShowDayId]
  );
  return rows;
}
export async function get10(offset?: number) {
  const values: any[] = offset ? [offset] : [];

  const result = await db.query(
    `SELECT * FROM movie_show_days LIMIT 10 ${offset ? `OFFSET $1` : ""}`,
    values
  );
  return result.rows;
}

export async function getWithFilter(reqQuery: getWithFilterReqQuery) {
  const query = {
    text: "SELECT * FROM movie_show_days WHERE",
    values: [],
  };

  helperFuncFilterByHasInstancesWithSeatsLeft(reqQuery, query);

  // handle date
  helperFuncFilterByDate(reqQuery, query);

  helperFunctionFilterByTimeOfDay(reqQuery, query);

  console.log(query);
  const { rows } = await db.query(query);
  return rows;
}

function helperFuncFilterByDate(
  reqQuery: getWithFilterReqQuery,
  query: DBquery
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
  query: DBquery
) {
  if (
    typeof reqQuery.has_instances_with_seats_left === "undefined" ||
    reqQuery.has_instances_with_seats_left
  ) {
    query.text += `${
      query.values.length ? " AND" : ""
    } has_instances_with_seats_left = TRUE`;
  }
}

function helperFunctionFilterByTimeOfDay(
  reqQuery: getWithFilterReqQuery,
  query: DBquery
) {
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

function needsAnd(reqQuery: getWithFilterReqQuery, query: DBquery) {
  if (query.values.length > 0) return true;
  if (
    typeof reqQuery.has_instances_with_seats_left === "undefined" ||
    reqQuery.has_instances_with_seats_left
  )
    return true;

  return false;
}
