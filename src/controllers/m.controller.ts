import ReqHandler from "src/types/RequestHandler";
import * as mRepository from "../Repositories/m.repository";
import { MFilter } from "src/dto/Search by filter/m.filter.dto";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";

export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(MFilter, req.query);
  if (errors.length) return HTTPResponses.BadRequest(res, errors);

  const offset = filter.page ? filter.page * 10 : 0;

  if (Object.keys(filter).length === 0) return await mRepository.getAll();

  try {
    if (Object.keys(filter).length === 1 && filter.page) {
      const showDays = await mRepository.get10(offset);
      return HTTPResponses.SuccessResponse(res, { showDays });
    } else {
      const showDays = await mRepository.getWithFilter(filter);
      return HTTPResponses.SuccessResponse(res, { showDays });
    }
  } catch (error) {
    console.log(error);
    return HTTPResponses.InternalServerError(res);
  }
};

// req.param
export const getByTitle: ReqHandler = async (req, res) => {
  const { title } = req.params;
  if (!title || title.trim() === "") return HTTPResponses.BadRequest(res);
  try {
    const movieByTitle = await mRepository.getByTitle(title);
    if (movieByTitle)
      return HTTPResponses.SuccessResponse(res, { movie: movieByTitle });
    const [error, movieById] = await getById(parseInt(title));
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
