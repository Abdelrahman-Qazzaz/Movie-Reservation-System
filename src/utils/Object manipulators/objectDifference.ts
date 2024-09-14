export type ObjectWithKeys = { [key: string]: boolean };
// Function to get the difference between object keys
export function getDifference(
  objA: ObjectWithKeys,
  objB: ObjectWithKeys
): ObjectWithKeys {
  let result: ObjectWithKeys = {};

  // Iterate over the keys of objA
  for (let key in objA) {
    // If the key is not in objB, add it to the result
    if (!objB.hasOwnProperty(key)) {
      console.log("foo");
      result[key] = objA[key];
    }
  }

  return result;
}
