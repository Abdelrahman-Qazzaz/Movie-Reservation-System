import { Prisma } from "@prisma/client";
import db from "src/db";
import { Filter } from "src/dto/Search by filter/Filter.dto";
import { MFilter } from "src/dto/Search by filter/M.filter.dto";
import { MsdFilter } from "src/dto/Search by filter/Msd.filter.dto";
import { MsdiFilter } from "src/dto/Search by filter/Msdi.filter.dto";

// Utility type to get the intersection of properties
type Intersection<T, U> = {
  [K in keyof T & keyof U]: T[K] extends U[K] ? K : never;
}[keyof T & keyof U];

// Utility type to exclude properties from T that are in the intersection with U
type ExcludeIntersection<T, U> = {
  [K in Exclude<keyof T, Intersection<T, U>>]: T[K];
};

//
type mWhereInput = Prisma.moviesScalarWhereWithAggregatesInput;

type msdWhereInput = {
  movies?: mWhereInput;
} & Prisma.movie_show_daysScalarWhereWithAggregatesInput;

type msdiWhereInput = {
  movie_show_days?: msdWhereInput;
} & Prisma.movie_show_days_instancesScalarWhereWithAggregatesInput;
//

//
type mOrderByInput = Prisma.moviesOrderByWithRelationInput;

type msdOrderByInput = {
  movies?: mOrderByInput;
} & Prisma.movie_show_daysOrderByWithRelationInput;

type msdiOrderByInput = {
  movie_show_days?: msdOrderByInput;
} & Prisma.movie_show_days_instancesOrderByWithRelationInput;
//

////
type m_findMany = {
  where: mWhereInput;
  orderBy: mOrderByInput;
};
type msd_findMany = {
  where: msdWhereInput;
  orderBy: msdOrderByInput;
};

type msdi_findMany = {
  where: msdiWhereInput;
  orderBy: msdiOrderByInput;
};
////

export class FindMany {
  where?: mWhereInput | msdWhereInput | msdiWhereInput;
  orderBy?: mOrderByInput | msdOrderByInput | msdiOrderByInput;
  take?: number;
  skip?: number;

  constructor(input: Filter | MFilter | MsdFilter | MsdiFilter) {
    var {
      limit,
      page,
      ...rest
    }: {
      limit?: number;
      page?: number;
      rest?: ExcludeIntersection<MFilter, Filter>;
    } = input;
    this.take = limit;
    this.skip = page ? page * 10 : 0;

    const m_findMany: m_findMany = {
      where: {},
      orderBy: {},
    };

    const msd_findMany: msd_findMany = {
      where: {},
      orderBy: {},
    };

    const msdi_findMany: msdi_findMany = {
      where: {},
      orderBy: {},
    };

    let final_findMany = null;

    if (rest) {
      console.log("foo");
      if (input instanceof MFilter) {
        var {
          languages,
          release_date_gt,
          release_date_lt,
          release_date,
          sort_by_popularity,
          ...restWhere
        } = rest as ExcludeIntersection<MFilter, Filter>;

        m_findMany.where = {
          ...m_findMany.where,
          ...restWhere,
          languages: { hasSome: languages },
          release_date: release_date ?? {
            gt: release_date_gt ?? undefined,
            lt: release_date_lt ?? undefined,
          },
        };

        m_findMany.orderBy = {
          popularity: sort_by_popularity ? "desc" : undefined,
        };
        final_findMany = m_findMany;
      }
      if (input instanceof MsdFilter) {
        const temp = rest as ExcludeIntersection<MsdFilter, MFilter>;

        const {
          date_gt,
          date_lt,
          date,
          time_of_day_gt,
          time_of_day_lt,
          sort_by_date,
          ...restWhere
        } = temp;

        msd_findMany.where = {
          movies: m_findMany.where,
          ...restWhere,
          date: date ?? { gt: date_gt ?? undefined, lt: date_lt ?? undefined },
        };
        msd_findMany.orderBy = {
          movies: m_findMany.orderBy,
          date: sort_by_date ? "desc" : undefined,
        };
        final_findMany = msd_findMany;
      }
      if (input instanceof MsdiFilter) {
        const temp = rest as ExcludeIntersection<MsdiFilter, MsdFilter>;
        const { ...restWhere } = temp;
        msdi_findMany.where = { ...restWhere };
        final_findMany = msdi_findMany;
      }
    }
    console.log("final_findMany");
    console.log(final_findMany);
    this.where = final_findMany?.where;
    this.orderBy = final_findMany?.orderBy;
  }
}
