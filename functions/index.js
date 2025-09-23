const functions = require('firebase-functions');
const Razorpay = require('razorpay');

// Replace with your test keys. These keys are safe in Cloud Functions.
const razorpay = new Razorpay({
  key_id: functions.config().razorpay.key_id,
  key_secret: functions.config().razorpay.key_secret,
});

exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  const amount = data.amount;
  const options = {
    amount: amount,
    currency: "INR",
    receipt: "receipt_order_" + Date.now(),
  };

  try {
    const order = await razorpay.orders.create(options);
    return { orderId: order.id };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Unable to create order.');
  }
});

// Add another function to verify the payment signature after a successful transaction