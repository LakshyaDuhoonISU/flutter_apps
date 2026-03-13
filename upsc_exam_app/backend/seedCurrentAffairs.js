// Script to add sample current affairs data
// Run with: node seedCurrentAffairs.js

require('dotenv').config();
const mongoose = require('mongoose');
const CurrentAffairs = require('./models/CurrentAffairs');

// MongoDB connection
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/upsc_exam_prep')
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

const sampleCurrentAffairs = {
    title: "Supreme Court Landmark Judgment on Article 370",
    date: new Date(),
    category: "Politics",
    summary: "The Supreme Court of India delivered a historic judgment regarding the abrogation of Article 370, which granted special status to Jammu and Kashmir. The five-judge Constitution Bench unanimously upheld the constitutional validity of the government's decision to revoke Article 370 in August 2019. The verdict emphasized the temporary nature of the provision and affirmed that the President had the power to issue the proclamation. This judgment has far-reaching implications for the constitutional framework and governance of the region.",
    quiz: [
        {
            question: "Which article of the Indian Constitution granted special status to Jammu and Kashmir?",
            options: ["Article 356", "Article 370", "Article 371", "Article 360"],
            correctAnswer: 1,
            explanation: "Article 370 granted special autonomous status to Jammu and Kashmir, which was abrogated in August 2019."
        },
        {
            question: "In which year was Article 370 abrogated?",
            options: ["2018", "2019", "2020", "2021"],
            correctAnswer: 1,
            explanation: "Article 370 was abrogated on August 5, 2019, by a presidential order."
        },
        {
            question: "How many judges were part of the Constitution Bench that delivered the verdict?",
            options: ["Three", "Five", "Seven", "Nine"],
            correctAnswer: 1,
            explanation: "A five-judge Constitution Bench of the Supreme Court delivered the unanimous verdict on Article 370."
        }
    ]
};

async function seedData() {
    try {
        // Delete existing current affairs for today
        await CurrentAffairs.deleteMany({});
        console.log('Cleared existing current affairs');

        // Insert new current affairs
        const result = await CurrentAffairs.create(sampleCurrentAffairs);
        console.log('Sample current affairs created successfully!');
        console.log('Title:', result.title);
        console.log('Date:', result.date);
        console.log('Category:', result.category);

        process.exit(0);
    } catch (error) {
        console.error('Error seeding data:', error);
        process.exit(1);
    }
}

seedData();
