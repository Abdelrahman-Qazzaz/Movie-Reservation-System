import bcrypt from "bcrypt";
async function comparePassword(plain: string, hashed: string) {
  return await bcrypt.compare(plain, hashed);
}

export default comparePassword;
