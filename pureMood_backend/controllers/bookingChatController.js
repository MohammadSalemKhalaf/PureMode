// Booking Chat Controller
// This file simply re-exports the chat-related handlers from bookingController
// so that routes/bookingChatRoutes.js can use a dedicated controller module

const bookingController = require('./bookingController');

module.exports = {
  getOrCreateSession: bookingController.getOrCreateSession,
  getMessages: bookingController.getMessages,
  sendMessage: bookingController.sendMessage,
};
