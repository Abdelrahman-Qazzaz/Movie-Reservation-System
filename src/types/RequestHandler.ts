import { Request, Response } from "express";

// Type definition for a function that takes a number and returns a string
type ReqHandler = (req: Request, res: Response) => any;

export default ReqHandler;
