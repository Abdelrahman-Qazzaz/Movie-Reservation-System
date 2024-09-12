import ReqHandler from "src/types/RequestHandler";
import { AdminAddMSDIInput } from "src/dto/Admin.add.msdi.dto";
import transformAndValidate from "src/utils/inputTransformAndValidate";
import * as HTTPResponses from "../utils/HTTPResponses";
import * as msdiRepository from "../Repositories/msdi.repository";
import * as msdRepository from "../Repositories/msd.repository";
import { MsdiFilter } from "src/dto/Search by filter/Msdi.filter.dto";

export const create: ReqHandler = async (req, res) => {
  const input = { ...req.body };
  const [errors, transformedInput] = await transformAndValidate(
    AdminAddMSDIInput,
    input
  );
  if (errors.length) return HTTPResponses.BadRequest(res, errors);

  const movie_show_day = await msdRepository.getById(
    transformedInput.movie_show_day_id
  );
  if (!movie_show_day)
    return HTTPResponses.BadRequest(res, {
      Message: `Movie Show Day with Id ${transformedInput.movie_show_day_id} does not exist.`,
    });

  try {
    await msdiRepository.add(transformedInput);
  } catch (error) {}
};

export const get: ReqHandler = async (req, res) => {
  const [errors, filter] = await transformAndValidate(MsdiFilter, req.query);
  console.log(filter);
  try {
    await msdiRepository.get(filter);
    HTTPResponses.SuccessResponse(res, await msdiRepository.get());
  } catch (error) {
    HTTPResponses.InternalServerError(res);
  }
};
