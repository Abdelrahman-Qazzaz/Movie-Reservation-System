import db from "src/db";
import { getWithFilterReqQuery } from "src/types/Movies/filter.movies";

export async function getAll() {
  return await db.movies.findMany();
}

export async function get10(skip: number = 0) {
  return await db.movies.findMany({ take: 10, skip });
}

export async function getWithFilter(
  reqQuery: getWithFilterReqQuery,
  offset: number = 0,
  limit: number = 0
) {
    await db.movies.findMany({where:{languages:{hasSome:}}})
    let where:{
        adult?:boolean;
        languages?:string[];
        release_date?:Date;
        release_date_gt?:Date; 
        release_date_lt?:Date;
    } = {}

    if(reqQuery.adult === 'true') {where.adult = true}





}


