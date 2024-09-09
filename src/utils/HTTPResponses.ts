import { Response } from "express";

export async function InternalServerError(res: Response) {
  return res.status(500).json({ Message: "Internal Server Error." });
}

export async function Unauthorized(res: Response, Message?: any) {
  return Message ? res.status(403).json(Message) : res.sendStatus(403);
}

export async function BadRequest(res: Response, Message?: any) {
  return Message ? res.status(400).json(Message) : res.sendStatus(400);
}
export async function SuccessResponse(res: Response, data?: any) {
  return data ? res.status(200).json(data) : res.sendStatus(200);
}
