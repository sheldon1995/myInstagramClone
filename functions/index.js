const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

// We write our functions here and then we are gonna use our terminal to deploy these functions to firebase cloud servers.


exports.observeComment = functions.database.ref('/comments/{postId}/{commentId}').onCreate((snapshot,context) =>{
  var postId = context.params.postId
  var commentId = context.params.commentId
  console.log('LOGGER -- the post id is ' + postId);

  return admin.database().ref('/comments/' +postId + '/' + commentId ).once('value', snapshot =>{
    var newComment = snapshot.val()
    var whoLeavesMessage = newComment.uid

  console.log('LOGGER -- the person who leave a comment is: ' + whoLeavesMessage);
  return admin.database().ref('/users/' + whoLeavesMessage).once('value', snapshot =>{
    // Grab all information of the followed user.
    var userWhoLeaveComment = snapshot.val();
    // Get his fcm token
    var userWhoLeaveCommentUserName = userWhoLeaveComment.username
    console.log('LOGGER -- ' + userWhoLeaveCommentUserName + ' leaved a comment');

    return admin.database().ref('/posts/' + postId).once('value', snapshot =>{
      var post = snapshot.val();
      var ownerId = post.ownerId
      return admin.database().ref('/users/' + ownerId).once('value',snapshot => {
        var userWhoGotComment = snapshot.val();
        var userWhoGotCommentUserName = userWhoGotComment.username
        var userWhoGotCommentFcmToken = userWhoGotComment.fcmToken
        console.log('LOGGER -- the user: ' + userWhoGotCommentUserName +' got a comment');
        // Design notificaiton message.
        var payload = {
          notification:{
            title : 'You have a new comment!',
            body : userWhoLeaveCommentUserName + ' commented on your post: ' + post.caption
          }
        }

      admin.messaging().sendToDevice(userWhoGotCommentFcmToken, payload)
        .then(function(response) {
        // See the MessagingDevicesResponse reference documentation for
        // the contents of response.
        console.log('Successfully sent message:', response);
      })
        .catch(function(error) {
        console.log('Error sending message:', error);
      });
      })
    })
  })
  })
});



exports.observeLikes = functions.database.ref('/user-likes/{uid}/{postId}').onCreate((snapshot,context) =>{
  var uid = context.params.uid
  var postId = context.params.postId
  console.log('LOGGER -- current user id is ' + uid);
  console.log('LOGGER -- he/she likes this post with id: ' + postId);
  return admin.database().ref('/posts/' + postId).once('value', snapshot =>{
    // Grab all information of the followed user.
    var postWasLiked = snapshot.val();
    // Get his fcm token
    var ownerId = postWasLiked.ownerId
    console.log('LOGGER -- the owner of this post is : ' + ownerId);
    return admin.database().ref('/users/' + ownerId).once('value', snapshot =>{
      var userWasLiked = snapshot.val();
      var userWasLikedFcmToken = userWasLiked.fcmToken
      console.log('LOGGER -- the owner username is : ' + userWasLiked.username);
      return admin.database().ref('/users/' + uid).once('value',snapshot => {
        var userToLike = snapshot.val();
        var userToLikeUserName = userToLike.username
        console.log('LOGGER -- the user to like user name is : ' + userToLikeUserName);
        // Design notificaiton message.
        var payload = {
          notification:{
            title : 'You have a new post like!',
            body : userToLikeUserName + ' liked your post.'
          }
        }

      admin.messaging().sendToDevice(userWasLikedFcmToken, payload)
        .then(function(response) {
        // See the MessagingDevicesResponse reference documentation for
        // the contents of response.
        console.log('Successfully sent message:', response);
      })
        .catch(function(error) {
        console.log('Error sending message:', error);
      });
      })
    })
  })
});


// Observe user-following structure and find two parameters "userId" and "followingUid"
exports.observeFollow = functions.database.ref('/user-following/{uid}/{followedUid}').onCreate((snapshot,context) =>{
  var uid = context.params.uid;
  var followedUid = context.params.followedUid;

  console.log('LOGGER -- uid that did following others is ' + uid);
  console.log('LOGGER -- he/she is following ' + followedUid);
  return admin.database().ref('/users/' + followedUid).once('value', snapshot =>{
    // Grab all information of the followed user.
    var userWasFollowed = snapshot.val();
    // Get his fcm token
    var registrationToken = userWasFollowed.fcmToken

    return admin.database().ref('/users/' + uid).once('value', snapshot =>{
      var userThatFollowed = snapshot.val();
      var payload = {
        notification:{
          title : 'You have a new follower!',
          body : userThatFollowed.username + ' started following you.'
        }
      }

    admin.messaging().sendToDevice(registrationToken, payload)
      .then(function(response) {
      // See the MessagingDevicesResponse reference documentation for
      // the contents of response.
      console.log('Successfully sent message:', response);
    })
      .catch(function(error) {
      console.log('Error sending message:', error);
    });
    })
  })
});

exports.helloWorld = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
});

exports.sendPushNotification = functions.https.onRequest((request,response) => {
  response.send("Attempting to send notification");
  // Send message to our individual device.
  console.log("LOGGER --- Trying to send push message...");
  var userId = 'CiCXXmWqMAU4M8QqksO5Vkerx4p1';

  // Fetch data according to user's id
  return admin.database().ref('/users/' + userId).once('value', snapshot =>{
    var user = snapshot.val();

    console.log("Username is "+ user.username);

    var payload = {
      notification:{
        title : 'Push Notification Title',
        body : 'Test notificaiton message'
      }
    }
    //var registrationToken = 'eD1_AKoWBUQTgxW7jXpO2M:APA91bHWo2MbyqY4V5voS1dRGd3Wh9y538muecs8T6aT8GGPO03M-fK8ij-Rm4kECeFNIiP6uO2TFdgVXAPOWYXynrFjFvQl5xlZJKCJlJceoU0rH9ZrZyP_S9iQ1CalSZ_7gYwsLOKS'
    var registrationToken = 'cCGldsIDI0O1vdaqTJMote:APA91bGNAvM6F5M-lFGYCY2fGsN_qN5xsRjRoVL7JD9YuzFqBIX8_fCwTlypLceOUDiUi0QMflcoC_LG9XEBA6cEzGj5mbVqa2AuV9JpYLJVOHOtpHP2tR6YwAzaSSF8Gn2QYASm1c-1'
  // Send a message to the device corresponding to the provided
// registration token.
  admin.messaging().sendToDevice(registrationToken, payload)
    .then(function(response) {
    // See the MessagingDevicesResponse reference documentation for
    // the contents of response.
    console.log('Successfully sent message:', response);
  })
    .catch(function(error) {
    console.log('Error sending message:', error);
  });
  })
});
