import ReqHandler from "src/types/RequestHandler";
import * as moviesController from "./moviesController";
import { AdminAddMovieShowDayInput } from "src/dto/AdminAddMovieShowDayInput";
import * as movieShowDaysRepository from "src/Repositories/movieShowDaysRepository";
import MsdFilterQuery from "src/dto/Search by filter/filter.movieShowDays.dto";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";
export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(
    MsdFilterQuery,
    req.query
  );
  if (errors.length) return HTTPResponses.BadRequest(res, errors);
  try {
    const movieShowDays = await movieShowDaysRepository.getWithFilter(filter);
    return HTTPResponses.SuccessResponse(res, movieShowDays);
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};

export const getById: ReqHandler = async (req, res) => {
  try {
    const movieShowDay = await movieShowDaysRepository.getById(
      parseInt(req.params.id)
    );
    return HTTPResponses.SuccessResponse(res, movieShowDay);
  } catch (error) {
    return HTTPResponses.InternalServerError(res);
  }
};

// get details about a movie show day
export const getDetails: ReqHandler = async (req, res) => {
  try {
    const movie_show_day_details =
      await movieShowDaysRepository.get_movie_show_day_details(
        parseInt(req.params.id)
      );
    return HTTPResponses.SuccessResponse(res, movie_show_day_details);
  } catch (error) {
    return HTTPResponses.InternalServerError(res);
  }
};

//admin only
export const add: ReqHandler = async (req, res) => {
  const [errors, input] = await transformAndValidate(
    AdminAddMovieShowDayInput,
    req.body
  );
  if (errors.length) return HTTPResponses.BadRequest(res, errors);
  try {
    const targetMovie = await moviesController.getById(input.movie_id);
    if (!targetMovie)
      return res
        .status(404)
        .json({ message: `Couldn't find a movie with id ${input.movie_id} ` });

    const Show_Day = await movieShowDaysRepository.insert(input);
    return HTTPResponses.SuccessResponse(res, Show_Day);
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};
