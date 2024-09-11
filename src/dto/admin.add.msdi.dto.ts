import { Transform } from "class-transformer";
import { IsDate, IsMilitaryTime, IsNotEmpty } from "class-validator";

export class AdminAddMSDIInput {
  @IsMilitaryTime()
  @Transform(({ value }) => value + ":00" /*add :SS*/, { toClassOnly: true })
  time: string;

  @IsNotEmpty()
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  movie_show_day_id: number;
}
