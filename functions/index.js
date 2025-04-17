const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
require("dotenv").config();

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

exports.sendEmailToDoctor = functions.firestore
  .document("donations/{donationId}") // Listens for new donations
  .onCreate((snapshot, context) => {
    const donationData = snapshot.data();
    const doctorEmail = "med4freee@gmail.com"; // Doctor's email

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: doctorEmail,
      subject: "New Medicine Donation Submitted",
      text: `Hello Doctor,

A new donor has submitted medicine details.

📌 **Donor Email:** ${donationData.donor_email}
💊 **Medicine Name:** ${donationData.medicine_name}
📝 **Dosage:** ${donationData.dosage}
📦 **Quantity:** ${donationData.quantity}
⏳ **Expiry Date:** ${donationData.expiry_date}

Please review the donation details.

Best regards,
Med4Free Team`,
    };

    return transporter.sendMail(mailOptions)
      .then(() => console.log("Email sent to doctor successfully."))
      .catch((error) => console.error("Error sending email:", error));
  });
