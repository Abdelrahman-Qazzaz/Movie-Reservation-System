import { Transform } from "class-transformer";

export class Filter {
  @Transform(({ value }) => Number(value), { toClassOnly: true })
  limit?: number;

  @Transform(({ value }) => Number(value), { toClassOnly: true })
  page?: number;
}
