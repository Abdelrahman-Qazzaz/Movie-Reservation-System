import { Transform } from "class-transformer";
import { IsDate, IsDateString, IsOptional } from "class-validator";
import { Filter } from "./filter.dto";

export class MFilter extends Filter {
  @Transform(
    ({ value }) => {
      if (value === "true" || value === true) {
        return true;
      }
      if (value === "false" || value === false) {
        return false;
      }
      return Boolean(value); // Converts to a primitive boolean
    },
    { toClassOnly: true }
  )
  adult?: boolean;

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
  languages?: string[];

  @IsOptional()
  @IsDateString()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  release_date?: Date;

  @IsOptional()
  @IsDateString()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  release_date_gt?: Date;

  @IsOptional()
  @IsDateString()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  release_date_lt?: Date;

  @Transform(
    ({ value }) => {
      if (value === "true" || value === true) {
        return true;
      }
      if (value === "false" || value === false) {
        return false;
      }
      return Boolean(value); // Converts to a primitive boolean
    },
    { toClassOnly: true }
  )
  sort_by_popularity?: boolean;
}
