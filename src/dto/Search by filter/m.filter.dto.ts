import { Transform } from "class-transformer";
import { IsArray, IsBoolean, IsDate, IsOptional } from "class-validator";
import { Filter } from "./Filter.dto";

export class MFilter extends Filter {
  @IsOptional()
  title: string;

  @IsOptional()
  @Transform(
    ({ value }) => {
      if (value === "true" || value === true) {
        return true;
      }
      if (value === "false" || value === false) {
        return false;
      }
    },
    { toClassOnly: true }
  )
  @IsBoolean()
  adult: boolean;

  @IsOptional()
  @Transform(({ value }) => (Array.isArray(value) ? value : [value]), {
    toClassOnly: true,
  })
  @Transform(
    ({ value }) =>
      value.map((val: string) => {
        return val[0].toUpperCase() + val.substring(1).toLowerCase();
      }),
    {
      toClassOnly: true,
    }
  )
  @IsArray()
  languages: string[];

  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  release_date: Date;

  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  release_date_gt: Date;

  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  release_date_lt: Date;

  @IsOptional()
  @Transform(
    ({ value }) => {
      if (value === "true") {
        return true;
      }
      if (value === "false") {
        return false;
      }
      return;
    },
    { toClassOnly: true }
  )
  @IsBoolean()
  sort_by_popularity: boolean;
}
