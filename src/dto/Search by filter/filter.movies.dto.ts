class MoviesSearchQuery {
  adult?: boolean;
  languages?: string[];
  release_date?: Date;
  release_date_gt?: Date;
  release_date_lt?: Date;
}

export default MoviesSearchQuery;
