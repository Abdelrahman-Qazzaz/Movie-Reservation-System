type MovieShowDay = {
  id: number;
  movie_id: number;
  date: Date;
  has_instances_with_seats_left: boolean | null;
  recursion_flag: boolean | null;
};

export default MovieShowDay;
