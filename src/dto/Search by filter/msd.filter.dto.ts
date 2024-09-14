import { Transform } from "class-transformer";
import { MFilter } from "./M.filter.dto";
import { IsBoolean, IsDate, IsOptional, IsString } from "class-validator";

export class MsdFilter extends MFilter {
  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  date: Date;

  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  date_gt: Date;

  @IsOptional()
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsDate()
  date_lt: Date;

  @IsOptional()
  time_of_day_gt: string;

  @IsOptional()
  @IsString()
  time_of_day_lt: string;

  @IsOptional()
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
  @IsBoolean()
  sort_by_date: boolean;

  @IsOptional()
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
  @IsBoolean()
  has_instances_with_seats_left: boolean;
}
