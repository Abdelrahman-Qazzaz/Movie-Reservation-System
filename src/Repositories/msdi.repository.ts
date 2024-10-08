import { movie_show_days_instances as movie_show_days_instance } from "@prisma/client";
import db from "../db";
import { AdminAddMSDIInput } from "src/dto/Admin.add.msdi.dto";
import { MsdiFilter } from "src/dto/Search by filter/Msdi.filter.dto";

export async function add(data: AdminAddMSDIInput) {
  return await db.movie_show_days_instances.create({
    data: { ...data, has_seats_left: false },
  });
}

export async function get(filter: MsdiFilter) {
  const { limit, page, ...where } = filter;
  return await db.movie_show_days_instances.findMany({
    include: { movie_show_days: true },
    where,
    skip: page ? page * 10 : undefined,
    take: limit ?? undefined,
  });
}
