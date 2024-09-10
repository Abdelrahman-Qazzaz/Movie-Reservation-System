import { Prisma } from "@prisma/client";
import db from "src/db";
import MoviesSearchQuery from "src/dto/Search by filter/filter.movies.dto";

export async function getAll() {
  return await db.movies.findMany();
}

export async function get10(skip: number = 0) {
  return await db.movies.findMany({ take: 10, skip });
}

export async function getById(id: number) {
  return await db.movies.findFirst({ where: { id } });
}

export async function getByTitle(title: string) {
  return await db.movies.findFirst({ where: { title } });
}

export async function getWithFilter(
  filter: MoviesSearchQuery,
  offset: number = 0,
  limit: number | undefined
) {
  let where: Prisma.moviesWhereInput = {};
  let orderBy = {} as any;

  if (filter.sort_by_popularity) {
    orderBy.popularity = "desc";
  }

  where.adult = filter.adult;

  where.languages = {};
  where.languages.hasSome = filter.languages;

  where.release_date = {};
  where.release_date = filter.release_date ?? {
    gt: filter.release_date_gt,
    lt: filter.release_date_lt,
  };

  return limit
    ? await db.movies.findMany({ where, orderBy, skip: offset, take: limit })
    : await db.movies.findMany({ where, orderBy, skip: offset });
}
