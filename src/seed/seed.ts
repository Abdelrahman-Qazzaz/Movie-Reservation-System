// import { da, faker } from "@faker-js/faker";
// import db from "./db.js";

// function generateRandomStartDateAndTimes() {
//   // Get today's date and Jan 1, 2028
//   const today = new Date();
//   const end = new Date(2028, 0, 1);

//   // Calculate the difference in milliseconds
//   const diff = end.getTime() - today.getTime();

//   // Generate a random number between 0 and the difference
//   const randomTime = Math.random() * diff;

//   // Add the random time to today's date
//   const randomDate = new Date(today.getTime() + randomTime);

//   const instances = [];
//   const oneTwoThree = Math.floor(Math.random() * 3) + 1;
//   for (let i = 0; i < oneTwoThree; i++) {
//     let instance = generateInstance(randomDate);
//     // if instance start is between another instances' elem's start and end, re generate.
//     while (checkForClashes(instance, instances)) {
//       instance = generateInstance(randomDate);
//     }
//     instances.push(instance);
//   }

//   return instances;
// }

// function generateInstance(randomDate) {
//   const instance = {
//     start: new Date(randomDate),
//     end: new Date(randomDate),
//   };
//   instance.start.setHours(Math.floor(Math.random() * 24));
//   instance.start.setMinutes(Math.floor(Math.random() * 2) * 30);

//   // Generate random duration between 1:30 and 2:30 hours
//   const randomDuration = 1.5 + Math.random() * 0.5; // Random number between 1.5 and 2
//   const durationInMilliseconds = randomDuration * 60 * 60 * 1000;

//   instance.end.setTime(instance.start.getTime() + durationInMilliseconds);

//   return instance;
// }
// function checkForClashes(instance, instances) {
//   if (instances.length === 0) return false;
//   for (const Instace of instances) {
//     if (instance.start >= Instace.start && instance.start <= Instace.end)
//       return true;
//   }

//   return false;
// }

// let i = 72;
// while (i <= 143) {
//   const seats = generateRandomSeats();
//   for (const seat of seats) {
//     db.query(
//       "INSERT INTO show_days_instances_tickets (seat_position,show_day_instance_id,reserved_by_user_id) VALUES($1,$2,$3)",
//       [seat, i, null]
//     );
//   }

//   i++;
// }

// function generateRandomSeats() {
//   const numOfSeats = Math.floor(Math.random() * (100 - 50 + 1)) + 50; // btwn 50 and 100
//   const seats = [];
//   let ROWS = [
//     "A",
//     "B",
//     "C",
//     "D",
//     "E",
//     "F",
//     "G",
//     "H",
//     "I",
//     "J",
//     "K",
//     "L",
//     "M",
//     "N",
//     "O",
//     "P",
//     "Q",
//     "R",
//     "S",
//     "T",
//     "U",
//     "V",
//     "W",
//     "X",
//     "Y",
//     "Z",
//   ];
//   let rowIndex = 0; // row index
//   let columnIndex = 0; // column index
//   while (seats.length < numOfSeats) {
//     seats.push(`${ROWS[rowIndex]}${columnIndex}`);

//     columnIndex++;
//     if (columnIndex === 10) {
//       columnIndex = 0;
//       rowIndex++;
//     }
//   }
//   return seats;
// }
