import { Transform } from "class-transformer";
import { MsdFilter } from "./Msd.filter.dto";
import { MFilter } from "./M.filter.dto";
import { Prisma } from "@prisma/client";
import db from "src/db";
import { IsNumber, IsOptional } from "class-validator";

export class MsdiFilter extends MsdFilter {
  @IsOptional()
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  @IsNumber()
  movie_show_day_id: number;
}
