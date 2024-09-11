import { Transform } from "class-transformer";
import { MSDFilter } from "./msd.filter.dto";

export class MsdiFilter extends MSDFilter {
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  movie_show_day_id?: number;
}
