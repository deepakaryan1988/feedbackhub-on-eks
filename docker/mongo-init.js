// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

db = db.getSiblingDB('feedbackhub');

// Create the feedbacks collection
db.createCollection('feedbacks');

// Create an index on the createdAt field for better query performance
db.feedbacks.createIndex({ "createdAt": -1 });

// Insert some sample data (optional)
db.feedbacks.insertMany([
  {
    name: "Sample User",
    message: "This is a sample feedback message to get you started!",
    createdAt: new Date()
  },
  {
    name: "Another User",
    message: "Great application! Looking forward to more features.",
    createdAt: new Date()
  }
]);

print('MongoDB initialized successfully!'); 