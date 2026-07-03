import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:education_app/core/utils/typedefs.dart';
import 'package:education_app/src/auth/data/models/user_model.dart';
import 'package:education_app/src/notifications/data/datasources/notification_remote_data_src.dart';
import 'package:education_app/src/notifications/data/models/notification_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NotificationRemoteDataSrc remoteDataSource;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() async {
    firestore = FakeFirebaseFirestore();

    final user = MockUser(
      uid: 'uid',
      email: 'email',
      displayName: 'displayName',
    );

    auth = MockFirebaseAuth(
      mockUser: user,
      signedIn: true,
    );

    remoteDataSource = NotificationRemoteDataSrcImpl(
      firestore: firestore,
      auth: auth,
    );
  });
  Future<QuerySnapshot<DataMap>> getNotifications() async => firestore
      .collection('users')
      .doc(auth.currentUser!.uid)
      .collection('notifications')
      .get();

  Future<DocumentReference> addNotification(
    NotificationModel notification,
  ) async {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('notifications')
        .add(notification.toMap());
  }

  group('sendNotification', () {
    test(
      'should upload a [Notification] to the specified user',
      () async {
        const secondUID = 'second_uid';
        for (var i = 0; i < 2; i++) {
          await firestore
              .collection('users')
              .doc(i == 0 ? auth.currentUser!.uid : secondUID)
              .set(
                const LocalUserModel.empty()
                    .copyWith(
                      uid: i == 0 ? auth.currentUser!.uid : secondUID,
                      email: i == 0 ? auth.currentUser!.email : 'second email',
                      fullName: i == 0
                          ? auth.currentUser!.displayName
                          : 'second name',
                    )
                    .toMap(),
              );
        }

        final notification = NotificationModel.empty().copyWith(
          id: '1',
          title: 'Test unique title, cannot be duplicated',
          body: 'Test',
        );

        await remoteDataSource.sendNotification(notification);

        final user1NotificationsRef = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .get();

        final user2NotificationsRef = await firestore
            .collection('users')
            .doc(secondUID)
            .collection('notifications')
            .get();

        expect(user1NotificationsRef.docs, hasLength(1));
        expect(
          user1NotificationsRef.docs.first.data()['title'],
          equals(notification.title),
        );
        expect(user2NotificationsRef.docs, hasLength(1));
        expect(
          user1NotificationsRef.docs.first.data()['title'],
          equals(notification.title),
        );
      },
    );
  });

  group('getNotifications', () {
    test(
      'should return a [Stream<List<Notification>>] when the call is '
      'successful',
      () async {
        final userId = auth.currentUser!.uid;

        await firestore
            .collection('users')
            .doc(userId)
            .set(const LocalUserModel.empty().copyWith(uid: userId).toMap());

        final expectedNotifications = [
          NotificationModel.empty(),
          NotificationModel.empty().copyWith(
            id: '1',
            sentAt: DateTime.now().add(
              const Duration(seconds: 50),
            ),
          ),
        ];
        for (final notification in expectedNotifications) {
          await addNotification(notification);
        }

        final result = remoteDataSource.getNotifications();

        expect(result, emitsInOrder([equals(expectedNotifications.reversed)]));
      },
    );

    test('should return a stream of empty list when an error occurs', () {
      final result = remoteDataSource.getNotifications();

      expect(result, emits(equals(<NotificationModel>[])));
    });
  });

  group('clear', () {
    test(
      'should delete the specified [Notification] from the database',
      () async {
        final firstDocRef = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .add(NotificationModel.empty().toMap());

        final notification = NotificationModel.empty().copyWith(id: '1');
        final docRef = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .add(notification.toMap());

        final collection = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .get();

        expect(
          collection.docs,
          hasLength(2),
        );

        await remoteDataSource.clear(docRef.id);
        final secondNotificationDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .doc(docRef.id)
            .get();
        final firstNotificationDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .doc(firstDocRef.id)
            .get();

        expect(
          secondNotificationDoc.exists,
          isFalse,
        );
        expect(
          firstNotificationDoc.exists,
          isTrue,
        );
      },
    );
  });

  group('clearAll', () {
    test(
      "should delete every notification in the current user's sub-collection",
      () async {
        for (var i = 0; i < 5; i++) {
          await addNotification(
            NotificationModel.empty().copyWith(id: i.toString()),
          );
        }

        final collection = await getNotifications();

        expect(
          collection.docs,
          hasLength(5),
        );

        await remoteDataSource.clearAll();
        final notificationDocs = await getNotifications();

        expect(
          notificationDocs.docs,
          isEmpty,
        );
      },
    );
  });

  group('markAsRead', () {
    test(
      'should mark the specified notification as read',
      () async {
        var tId = '';

        for (var i = 0; i < 5; i++) {
          final docRef = await addNotification(
            NotificationModel.empty().copyWith(
              id: i.toString(),
              seen: i.isEven,
            ),
          );
          if (i == 1) {
            tId = docRef.id;
          }
        }

        final collection = await getNotifications();

        expect(
          collection.docs,
          hasLength(5),
        );

        await remoteDataSource.markAsRead(tId);
        final notificationDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('notifications')
            .doc(tId)
            .get();

        expect(
          notificationDoc.data()!['seen'],
          isTrue,
        );
      },
    );
  });
}
