import ReqHandler from "src/types/RequestHandler";
import db from "../db";
import * as moviesRepository from "../Repositories/moviesRepository";
export const get: ReqHandler = async (req: { query: any }, res) => {
  let { page, limit } = req.query;
  limit = Number(limit);
  const offset = page ? page * 10 : 0;

  if (Object.keys(req.query).length === 0)
    return await moviesRepository.getAll();

  if (Object.keys(req.query).length === 1 && page) {
    const showDays = await moviesRepository.get10(offset);
    return res.json({ showDays });
  } else {
    const showDays = await moviesRepository.getWithFilter(
      req.query,
      offset,
      limit
    );
    return res.json({ showDays });
  }
};

// req.param
export const getByTitle: ReqHandler = async (req, res) => {
  const { title } = req.params;
  if (!title || title.trim() === "") return res.sendStatus(400);
  const rows = await db.query("SELECT * FROM movies WHERE TITLE LIKE $1", [
    `%${title}%`,
  ]);

  res.json({ movies: rows });
};

export const getById = async (id: number) => {
  const rows = await db.query("SELECT * FROM movies WHERE id = $1", [id]);
  return rows.length ? rows[0] : null;
};
type reqQuery = {
  languages: string[];
  release_date_gt: string;
  release_date_lt: string;
  sort_by_popularity: string;
  adult: string;
};
// req.query
async function getWithFilter(reqQuery: reqQuery) {
  const keys = Object.keys(reqQuery);
  const query: { text: string; values: any[] } = {
    text: "SELECT * FROM movies WHERE",
    values: [],
  };

  keys.map((key, idx) => {
    if (
      key !== "languages" &&
      key !== "release_date_gt" &&
      key !== "release_date_lt" &&
      key !== "sort_by_popularity" &&
      key !== "adult"
    ) {
      query.values.push(reqQuery[key as keyof reqQuery]);
      query.text += `${idx === 0 ? " " : " AND "}${key} = $${
        query.values.length
      }`;
    } else if (key === "languages") {
      let values;
      // if the user is filtering by one language
      if (typeof reqQuery[key] !== "object") {
        values = [reqQuery[key]];
      } else {
        values = reqQuery[key];
      }
      values.map((value, idx) => {
        query.values.push(format(value));
        query.text += `${idx === 0 ? " " : " AND "}$${
          query.values.length
        } = ANY(languages)`;

        function format(string: string) {
          return string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();
        }
      });
    } else if (key === "release_date_gt") {
      query.values.push(reqQuery[key]);
      query.text += `${idx === 0 ? " " : " AND "}release_date > $${
        query.values.length
      }::DATE`;
    } else if (key === "release_date_lt") {
      query.values.push(reqQuery[key]);
      query.text += `${idx === 0 ? " " : " AND "}release_date < $${
        query.values.length
      }::DATE`;
    } else if (key === "adult") {
      query.values.push(reqQuery[key]);
      query.text += `${idx === 0 ? " " : " AND "}adult = $${
        query.values.length
      }`;
    }
  });

  if (Object.keys(reqQuery).includes("sort_by_popularity")) {
    query.text += " ORDER BY popularity DESC ";
  }

  console.log(query);
  try {
    const rows = await db.query(query);
    return rows;
  } catch (error) {
    console.log(error);
    return [];
  }
}
