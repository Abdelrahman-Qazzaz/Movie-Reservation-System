export function validatePassword(password: string | undefined) {
  if (password === undefined) return false;
  if (password.length < 6) return false;
  if (!password.includes("@" || "!" || "_" || "-" || "/")) return false;
  if (
    !password.includes(
      "0" || "1" || "2" || "3" || "4" || "5" || "6" || "7" || "8" || "9"
    )
  )
    return false;
  return true;
}
