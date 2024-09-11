import ReqHandler from "src/types/RequestHandler";
import { AdminAddMovieShowDayInstanceInput } from "src/dto/AdminAddMovieShowDayInstanceInput";
import * as moviesShowDaysInstancesRepository from "../Repositories/movieShowDaysInstancesRepository";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";
import * as movieShowDaysRepository from "../Repositories/movieShowDaysRepository";

export const create: ReqHandler = async (req, res) => {
  const input = { ...req.body };
  const [errors, transformedInput] = await transformAndValidate(
    AdminAddMovieShowDayInstanceInput,
    input
  );
  if (errors.length) return HTTPResponses.BadRequest(res, errors);

  const movie_show_day = await movieShowDaysRepository.getById(
    transformedInput.movie_show_day_id
  );
  if (!movie_show_day)
    return HTTPResponses.BadRequest(res, {
      Message: `Movie Show Day with Id ${transformedInput.movie_show_day_id} does not exist.`,
    });

  try {
    await moviesShowDaysInstancesRepository.add(transformedInput);
  } catch (error) {}
};

export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(temp, req.body);
  try {
    HTTPResponses.SuccessResponse(
      res,
      await moviesShowDaysInstancesRepository.get()
    );
  } catch (error) {
    HTTPResponses.InternalServerError(res);
  }
};
