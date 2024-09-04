import env from "dotenv";
import pg from "pg";
env.config();
const db = new pg.Client({
  user: process.env.DBUSER,
  host: process.env.DBHOST,
  database: process.env.DBDATABASE,
  password: process.env.DBPASSWORD,
  port: 5432,
});
db.connect();

export default db;
