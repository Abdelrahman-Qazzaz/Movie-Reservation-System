import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";

function Email(props: any) {
  var _props$ticket,
    _props$ticket2,
    _props$movie,
    _props$dateAndTime,
    _props$dateAndTime2;
  return /*#__PURE__*/ _jsxs("div", {
    style: {
      backgroundColor: "#FC3C3C",
      maxWidth: "420px",
      padding: "0.25rem",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
    },

    children: [
      /*#__PURE__*/ _jsxs("div", {
        style: { paddingBottom: "0.25rem" },
        children: [
          "Dear ",
          props.customer_name || "Customer",
          ", Thank you for purchasing a movie ticket from us. Your purchase has been successfully processed.",
        ],
      }),
      /*#__PURE__*/ _jsxs("div", {
        style: {
          width: "fit-content",
          borderRadius: "0.1rem",
          border: "1px solid #dee2e6",
          backgroundColor: "#f8f9fa",
          padding: "0.25rem",
        },

        children: [
          /*#__PURE__*/ _jsx("div", {
            style: {
              borderBottom: "1px solid #dee2e6",
              paddingTop: "0.25rem",
              paddingBottom: "0.25rem",
              marginBottom: "0.5rem",
            },
            children: "Ticket Infortmation:",
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginTop: "0.5rem",
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: [
              "Id: ",
              (_props$ticket = props.ticket) === null ||
              _props$ticket === void 0
                ? void 0
                : _props$ticket.id,
            ],
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: ["Theater: ", props.theater],
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: [
              "Seat position: ",
              (_props$ticket2 = props.ticket) === null ||
              _props$ticket2 === void 0
                ? void 0
                : _props$ticket2.seat_position,
            ],
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: [
              "Movie: ",
              (_props$movie = props.movie) === null || _props$movie === void 0
                ? void 0
                : _props$movie.movie_title,
            ],
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: [
              "Date: ",
              (_props$dateAndTime = props.dateAndTime) === null ||
              _props$dateAndTime === void 0
                ? void 0
                : _props$dateAndTime.date + "",
            ],
          }),
          /*#__PURE__*/ _jsxs("div", {
            style: {
              marginBottom: "0.5rem", // Equivalent to mb-2
              paddingLeft: "0.25rem", // Equivalent to ps-1
            },
            children: [
              "Time: ",
              (_props$dateAndTime2 = props.dateAndTime) === null ||
              _props$dateAndTime2 === void 0
                ? void 0
                : _props$dateAndTime2.time + "",
            ],
          }),
        ],
      }),
    ],
  });
}
export default Email;
