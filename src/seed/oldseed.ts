// import { faker } from "@faker-js/faker";
// import db from "./db.js";
// const languages = [
//   "English",
//   "Spanish",
//   "French",
//   "German",
//   "Chinese",
//   "Japanese",
//   "Arabic",
//   "Russian",
//   "Portuguese",
//   "Hindi",
//   "Italian",
//   "Korean",
//   "Polish",
//   "Dutch",
//   "Swedish",
//   "Turkish",
//   "Vietnamese",
//   "Greek",
//   "Czech",
//   "Persian",
// ];

// function generateFakeMovie() {
//   const movie = {
//     title: faker.lorem.words(3),
//     releaseDate: faker.date.past().toISOString().split("T")[0],
//     languages: getRandomElements(languages, languages.length),
//     description: faker.lorem.paragraph(),
//     tagline: faker.lorem.sentence(),
//     popularity: faker.datatype.float({ min: 0, max: 100 }),
//     voteAverage: faker.datatype.float({ min: 0, max: 10 }),
//     voteCount: faker.datatype.number({ min: 0, max: 10000 }),
//     adult: faker.datatype.boolean(),
//     imdbId: faker.datatype.uuid(),
//     showDays: [],
//   };

//   const one_to_5 = Math.floor(Math.random() * 5) + 1;
//   for (let i = 0; i < one_to_5; i++) {
//     let showTime = generateRandomStartDateAndTimes();

//     movie.showDays.push(showTime);
//   }

//   movie.showDays.map((day, index) => {
//     day = { date: "", times: [...day] };
//     day.times.sort((a, b) => a.start - b.start);

//     let temp = day.times[0];
//     day.date = temp.start.toISOString().split("T")[0];
//     movie.showDays[index] = day;
//   });

//   for (const showDay of movie.showDays) {
//     for (const time of showDay.times) {
//       time.seats = generateRandomSeats(); // array of objects.... array of seats
//     }
//   }

//   return movie;
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
//     seats.push({
//       seatName: `${ROWS[rowIndex]}${columnIndex}`,
//       reservedByUserId: null,
//     });
//     columnIndex++;
//     if (columnIndex === 10) {
//       columnIndex = 0;
//       rowIndex++;
//     }
//   }
//   return seats;
// }

// for (let i = 1; i < 1000; i++) {
//   const movie = generateFakeMovie();
//   if (await hasDuplicateTitle(movie.title)) break;
//   db.query(
//     "INSERT INTO movies (movie_title,release_date,languages,description,popularity,voteAverage,voteCount,adult,image_url) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)",
//     [
//       movie.title,
//       movie.releaseDate,
//       movie.languages,
//       movie.description,
//       movie.popularity,
//       movie.voteAverage,
//       movie.voteCount,
//       movie.adult,

//       `https://picsum.photos/id/${i}/200/300`,
//     ]
//   );
// }

// async function hasDuplicateTitle(movieTitle) {
//   const { rows } = await db.query(
//     "SELECT * FROM movies WHERE movie_title = $1",
//     [movieTitle]
//   );
//   if (rows.length > 0) {
//     return true;
//   }
//   return false;
// }
// function getRandomElements(array, maxCount) {
//   const length = Math.min(array.length, maxCount);
//   const count = Math.floor(Math.random() * length) + 1; // Ensure at least one element
//   const shuffled = array.sort(() => 0.5 - Math.random()); // Shuffle the array
//   return shuffled.slice(0, count);
// }

// /*
// the 3 functions below work together to achieve the following:
// 1. generate a date
// 2. for that date generate 1/2/3 start-end instances
// */
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
