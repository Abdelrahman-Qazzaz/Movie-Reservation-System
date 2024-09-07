export type getWithFilterReqQuery = {
  date?: string;
  date_lt?: string;
  date_gt?: string;
  has_instances_with_seats_left?: string;
  time_of_day_gt?: string;
  time_of_day_lt?: string;
};

export type WhereClause = any;
