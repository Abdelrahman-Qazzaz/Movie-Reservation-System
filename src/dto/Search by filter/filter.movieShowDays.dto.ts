import { Transform } from "class-transformer";
import { IsBoolean } from "class-validator";

class MsdFilterQuery {
  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  date?: Date;

  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  date_gt?: Date;

  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  date_lt?: Date;

  time_of_day_gt?: string;
  time_of_day_lt?: string;

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
  has_instances_with_seats_left?: boolean;
}

export default MsdFilterQuery;
