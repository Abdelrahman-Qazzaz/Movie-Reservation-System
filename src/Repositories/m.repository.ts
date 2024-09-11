import { Prisma } from "@prisma/client";
import db from "src/db";
import { MFilter } from "src/dto/Search by filter/m.filter.dto";

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

export async function getWithFilter(filter: MFilter) {
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

  const offset = filter.page ? filter.page * 10 : 0;

  return filter.limit
    ? await db.movies.findMany({
        where,
        orderBy,
        skip: offset,
        take: filter.limit,
      })
    : await db.movies.findMany({ where, orderBy, skip: offset });
}
