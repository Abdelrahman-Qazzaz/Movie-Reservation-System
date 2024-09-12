import ReqHandler from "src/types/RequestHandler";
import { AdminAddMSDInput } from "src/dto/Admin.add.msd.dto";
import * as msdRepository from "src/Repositories/msd.repository";
import { MSDFilter } from "src/dto/Search by filter/Msd.filter.dto";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";
import * as mRepository from "../Repositories/m.repository";
export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(MSDFilter, req.query);
  if (errors.length) return HTTPResponses.BadRequest(res, errors);
  try {
    const movieShowDays = await msdRepository.getWithFilter(filter);
    return HTTPResponses.SuccessResponse(res, movieShowDays);
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};

export const getById: ReqHandler = async (req, res) => {
  try {
    const movieShowDay = await msdRepository.getById(parseInt(req.params.id));
    return HTTPResponses.SuccessResponse(res, movieShowDay);
  } catch (error) {
    return HTTPResponses.InternalServerError(res);
  }
};

// get details about a movie show day
export const getDetails: ReqHandler = async (req, res) => {
  try {
    const movie_show_day_details =
      await msdRepository.get_movie_show_day_details(parseInt(req.params.id));
    return HTTPResponses.SuccessResponse(res, movie_show_day_details);
  } catch (error) {
    return HTTPResponses.InternalServerError(res);
  }
};

//admin only
export const add: ReqHandler = async (req, res) => {
  const [errors, input] = await transformAndValidate(
    AdminAddMSDInput,
    req.body
  );
  if (errors.length) return HTTPResponses.BadRequest(res, errors);
  try {
    const targetMovie = await mRepository.getById(input.movie_id);
    if (!targetMovie)
      return res
        .status(404)
        .json({ message: `Couldn't find a movie with id ${input.movie_id} ` });

    const Show_Day = await msdRepository.insert(input);
    return HTTPResponses.SuccessResponse(res, Show_Day);
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};
