import cron from "node-cron";
import db from "../db";
function cronScheduler() {
  cron.schedule("*/10 * * * *", async () => {
    // every 10 minutes
    await db.query(
      "SELECT node_cron_remove_outdated_movie_show_days_cascading()"
    );
  });
}

export default cronScheduler;
