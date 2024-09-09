import { Transform } from "class-transformer";
import { IsDate, IsNotEmpty } from "class-validator";

export class AdminAddMovieShowDayInput {
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  @IsNotEmpty()
  movie_id: number;

  @Transform(({ value }) => new Date(value), { toClassOnly: true })
  @IsNotEmpty()
  @IsDate()
  date: Date;
}
