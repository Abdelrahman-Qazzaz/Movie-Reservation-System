import { Transform } from "class-transformer";
import { IsNumber, IsOptional } from "class-validator";

export class Filter {
  @IsOptional()
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  @IsNumber()
  limit: number;

  @IsOptional()
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  @IsNumber()
  page: number;
}
