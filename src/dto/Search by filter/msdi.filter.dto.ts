import { Transform } from "class-transformer";
import { MSDFilter } from "./Msd.filter.dto";
import { MFilter } from "./M.filter.dto";
import { Prisma } from "@prisma/client";
import db from "src/db";

export class MsdiFilter extends MSDFilter {
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  movie_show_day_id?: number;
}
