import ReqHandler from "src/types/RequestHandler";
import db from "../db";
import * as moviesController from "./moviesController";
import { validate } from "class-validator";
import { AdminAddMovieShowDayInput } from "src/types/dto/AdminAddMovieShowDayInput";
import { plainToInstance } from "class-transformer";
import * as movieShowDaysRepository from "src/Repositories/movieShowDaysRepository";

export const get: ReqHandler = async (req: { query: any }, res) => {
  let { page, limit } = req.query;
  limit = Number(limit);
  const offset = page ? page * 10 : 0;

  if (Object.keys(req.query).length === 0)
    return await movieShowDaysRepository.getAll();

  if (Object.keys(req.query).length === 1 && page) {
    const showDays = await movieShowDaysRepository.get10(offset);
    return res.json({ showDays });
  } else {
    const showDays = await movieShowDaysRepository.getWithFilter(
      req.query,
      offset,
      limit
    );
    return res.json({ showDays });
  }
};

export const getById: ReqHandler = async (req, res) => {
  const showDay = await movieShowDaysRepository.getById(req.params.id);
  return res.json({ showDay });
};

// get details about a movie show day
export const getDetails: ReqHandler = async (req, res) => {
  const movie_show_day_details =
    await movieShowDaysRepository.get_movie_show_day_details(req.params.id);
  return res.json({ movie_show_day_details });
};

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
    const Show_Day = await movieShowDaysRepository.insert(
      input.movie_id,
      input.date
    );
    return res.status(201).json({ Show_Day });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal server error", error });
  }
};
