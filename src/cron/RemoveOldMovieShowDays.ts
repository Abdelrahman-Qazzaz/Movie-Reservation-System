import cron from "node-cron";
import db from "../db";
function cronScheduler() {
  cron.schedule("*/10 * * * *", () => {
    // every 10 minutes

    await db.query("");
  });
}

export default cronScheduler;
