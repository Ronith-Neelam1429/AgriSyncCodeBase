// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);

admin.initializeApp();

exports.createConnectAccount = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    const userData = userDoc.data();
    
    // Create a Stripe account if user doesn't already have one
    if (!userData.stripeAccountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        country: data.country || 'US',
        email: userData.email || context.auth.token.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: 'individual',
      });
      
      // Update user with Stripe account ID
      await admin.firestore().collection('users').doc(userId).update({
        stripeAccountId: account.id,
        stripeAccountStatus: 'pending',
      });
      
      // Generate account link for onboarding
      const accountLink = await stripe.accountLinks.create({
        account: account.id,
        refresh_url: `${data.baseUrl}/stripe-connect-refresh?userId=${userId}`,
        return_url: `${data.baseUrl}/stripe-connect-success?userId=${userId}`,
        type: 'account_onboarding',
      });
      
      return {
        accountId: account.id,
        accountLinkUrl: accountLink.url,
      };
    } else {
      // If account already exists, generate a new account link
      const accountLink = await stripe.accountLinks.create({
        account: userData.stripeAccountId,
        refresh_url: `${data.baseUrl}/stripe-connect-refresh?userId=${userId}`,
        return_url: `${data.baseUrl}/stripe-connect-success?userId=${userId}`,
        type: 'account_onboarding',
      });
      
      return {
        accountId: userData.stripeAccountId,
        accountLinkUrl: accountLink.url,
      };
    }
  } catch (error) {
    console.error('Error creating Stripe Connect account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Updates the Stripe account status in Firestore after onboarding
 */
exports.updateStripeAccountStatus = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    const userData = userDoc.data();
    
    if (!userData.stripeAccountId) {
      throw new functions.https.HttpsError('not-found', 'No Stripe account found for this user');
    }
    
    // Retrieve the account from Stripe to check its status
    const account = await stripe.accounts.retrieve(userData.stripeAccountId);
    
    // Update the account status in Firestore
    let stripeAccountStatus = 'pending';
    
    if (account.charges_enabled && account.payouts_enabled) {
      stripeAccountStatus = 'active';
    } else if (account.details_submitted) {
      stripeAccountStatus = 'submitted';
    }
    
    await admin.firestore().collection('users').doc(userId).update({
      stripeAccountStatus: stripeAccountStatus
    });
    
    return { status: stripeAccountStatus };
  } catch (error) {
    console.error('Error updating Stripe account status:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Creates a fresh account link for users who need to complete onboarding
 */
exports.refreshAccountLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    const userData = userDoc.data();
    
    if (!userData.stripeAccountId) {
      throw new functions.https.HttpsError('not-found', 'No Stripe account found for this user');
    }
    
    const accountLink = await stripe.accountLinks.create({
      account: userData.stripeAccountId,
      refresh_url: `${data.baseUrl}/stripe-connect-refresh?userId=${userId}`,
      return_url: `${data.baseUrl}/stripe-connect-success?userId=${userId}`,
      type: 'account_onboarding',
    });
    
    return { url: accountLink.url };
  } catch (error) {
    console.error('Error refreshing account link:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});