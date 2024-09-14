import ReqHandler from "src/types/RequestHandler";
import * as mRepository from "../Repositories/m.repository";
import { MFilter } from "src/dto/Search by filter/M.filter.dto";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";
import { FindMany } from "src/utils/FindMany/FindMany";
import db from "src/db";
import { fromInstanceToPlain } from "src/utils/Object manipulators/fromInstanceToPlain";

export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(MFilter, req.query);
  if (errors.length) return HTTPResponses.BadRequest(res, errors);
  console.log(filter);
  const findMany = new FindMany(filter);
  await db.movies.findMany(fromInstanceToPlain(findMany));
};

export const getByTitle: ReqHandler = async (req, res) => {
  const { title } = req.params;
  if (!title || title.trim() === "") return HTTPResponses.BadRequest(res);
  try {
    const movieByTitle = await mRepository.getByTitle(title);
    if (movieByTitle)
      return HTTPResponses.SuccessResponse(res, { movie: movieByTitle });
    const [error, movieById] = await getById(parseInt(title)); // this is incase someone tries to get a movie by id instead...
    return error
      ? HTTPResponses.BadRequest(res)
      : HTTPResponses.SuccessResponse(res, { movie: movieById });
  } catch (error) {
    return HTTPResponses.InternalServerError(res);
  }
};

const getById = async (id: number) => {
  try {
    return [null, await mRepository.getById(id)];
  } catch (error) {
    return [error, null];
  }
};
