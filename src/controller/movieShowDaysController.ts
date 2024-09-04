import ReqHandler from "src/types/RequestHandler";
import db from "../db";
import * as moviesController from "./moviesController";
import { validate } from "class-validator";
import { AdminAddMovieShowDayInput } from "src/types/dto/AdminAddMovieShowDayInput";
import { plainToInstance } from "class-transformer";
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
export const get: ReqHandler = async (req: { query: any }, res) => {
  const { page } = req.query;
  const offset = page ? page * 10 : 0;
  if (
    Object.keys(req.query).length === 0 ||
    (Object.keys(req.query).length === 1 && page)
  ) {
    const result = await db.query(
      `SELECT * FROM movie_show_days LIMIT 10 OFFSET ${offset}`
    );
    const showDays = result.rows;
    return res.json({ showDays });
  } else {
    const showDays = await getWithFilter(req.query);
    return res.json({ showDays });
  }
};

export const getById: ReqHandler = async (req, res) => {
  const { rows } = await db.query(
    "SELECT * FROM movie_show_days WHERE id = $1",
    [req.params.id]
  );
  const showDay = rows[0];
  return res.json({ showDay });
};

async function getWithFilter(reqQuery: getWithFilterReqQuery) {
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

// get details about a movie show day
export const getDetails: ReqHandler = async (req, res) => {
  const movieShowDayId = req.params.id;
  const { rows } = await db.query(
    `SELECT * FROM get_movie_show_day_details(${movieShowDayId})`
  );
  console.log(rows);
  return res.json({ movie_show_day_details: rows });
};
function needsAnd(reqQuery: getWithFilterReqQuery, query: DBquery) {
  if (query.values.length > 0) return true;
  if (
    typeof reqQuery.has_instances_with_seats_left === "undefined" ||
    reqQuery.has_instances_with_seats_left
  )
    return true;

  return false;
}

//admin only
export const add: ReqHandler = async (req, res) => {
  const input: { movie_id: number; date: string } = { ...req.body };
  const errors = await validate(
    plainToInstance(AdminAddMovieShowDayInput, input)
  );
  if (errors.length) return res.status(400).json({ errors });

  const targetMovie = await moviesController.getById(input.movie_id);
  if (!targetMovie)
    return res
      .status(404)
      .json({ message: `Couldn't find a movie with id ${input.movie_id} ` });

  try {
    const results = await db.query(
      "INSERT INTO movie_show_days (movie_id,date) VALUES($1,$2)",
      [input.movie_id, input.date]
    );
    console.log(results);
    return res.status(201).json({ Show_Day: results.rows[0] });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal server error", error });
  }
};
