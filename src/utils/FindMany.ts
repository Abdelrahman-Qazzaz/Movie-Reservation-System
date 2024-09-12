import { Prisma } from "@prisma/client";
import { Filter } from "src/dto/Search by filter/Filter.dto";
import { MFilter } from "src/dto/Search by filter/M.filter.dto";
import { MSDFilter } from "src/dto/Search by filter/Msd.filter.dto";
import { MsdiFilter } from "src/dto/Search by filter/Msdi.filter.dto";

type PrismaWhereClauses =
  | Prisma.moviesWhereInput
  | Prisma.movie_show_daysWhereInput
  | Prisma.movie_show_days_instancesWhereInput;
type PrismaOrderByClause =
  | Prisma.moviesOrderByWithAggregationInput
  | Prisma.movie_show_daysOrderByWithAggregationInput;

export class FindMany {
  where?: PrismaWhereClauses;
  orderBy?: PrismaOrderByClause;
  take?: number;
  offset?: number;

  constructor(input: Filter | MFilter | MSDFilter | MsdiFilter) {
    const { limit, page } = input;
    this.take = limit;
    this.offset = page ? page * 10 : 0;

    else if (input instanceof MSDFilter) {
        [this.where, this.orderBy] = MSD_MakeFindMany(input);
    }
    else if (input instanceof MFilter) {
      [this.where, this.orderBy] = M_MakeFindMany(this.where,input);

    }
  }
}

function MSD_MakeFindMany(
    currentWhere:Prisma.movie_show_daysWhereInput,
    input:MSDFilter
): [Prisma.movie_show_daysWhereInput, Prisma.movie_show_daysOrderByWithAggregationInput]{
    const orderBy: Prisma.movie_show_daysOrderByWithAggregationInput = {};
    
    if(input.sort_by_date){orderBy.date = 'asc'}
    if(input.date_gt){
        currentWhere.date = {gt:input.date_gt}
    }
    if(input.date_lt){
        currentWhere.date = {lt:input.date_lt}
    }
    if(input.)
        

   return [currentWhere,orderBy]
}
function M_MakeFindMany(
    currentWhere:Prisma.moviesWhereInput,
  input: MFilter
): [Prisma.moviesWhereInput, Prisma.moviesOrderByWithAggregationInput] {
  const {
    languages,
    release_date_gt,
    release_date_lt,
    sort_by_popularity,
    ...rest
  } = input;

  const orderBy: Prisma.moviesOrderByWithAggregationInput = {};
  if (release_date_gt) {
    currentWhere.release_date = { gt: release_date_gt };
  }
  if (release_date_lt) {
    currentWhere.release_date = { lt: release_date_lt };
  }
  if (languages) {
    currentWhere.languages = {
      hasSome: Array.isArray(languages) ? languages : [languages],
    };
  }
  if (sort_by_popularity) {
    orderBy.popularity = "desc";
  }

  currentWhere = { ...currentWhere, ...rest };
  return [currentWhere, orderBy];
}
