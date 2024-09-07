import { IsDateString, IsNotEmpty } from "class-validator";

export class AdminAddMovieShowDayInput {
  @IsNotEmpty()
  movie_id: number;

  @IsDateString()
  @IsNotEmpty()
  date: string;

  constructor(movie_id: number, date: string) {
    this.movie_id = movie_id;
    this.date = date;
  }
}
