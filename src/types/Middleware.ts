import { Request, Response, NextFunction } from "express";

// Type definition for a function that takes a number and returns a string
type Middleware = (req: Request, res: Response, next: NextFunction) => any;

export default Middleware;
