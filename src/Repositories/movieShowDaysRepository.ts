import db from "../db";

export async function get() {}

export async function get10(offset?: number) {
  const values: any[] = offset ? [offset] : [];

  const result = await db.query(
    `SELECT * FROM movie_show_days LIMIT 10 ${offset ? `OFFSET $1` : ""}`,
    values
  );
  return result.rows;
}
