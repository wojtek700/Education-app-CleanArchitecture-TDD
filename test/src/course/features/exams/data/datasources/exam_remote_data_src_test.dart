import 'package:education_app/src/auth/data/models/user_model.dart';
import 'package:education_app/src/course/data/models/course_model.dart';
import 'package:education_app/src/course/features/exams/data/datasources/exam_remote_data_src.dart';
import 'package:education_app/src/course/features/exams/data/models/exam_model.dart';
import 'package:education_app/src/course/features/exams/data/models/exam_question_model.dart';
import 'package:education_app/src/course/features/exams/data/models/user_choice_model.dart';
import 'package:education_app/src/course/features/exams/data/models/user_exam_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExamRemoteDataSrc remoteDataSource;
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

    remoteDataSource = ExamRemoteDataSrcImpl(
      firestore: firestore,
      auth: auth,
    );
  });

  group('uploadExam', () {
    test(
      'should upload the given [Exam] to the firestore and separate the '
      '[Exam] and the [Exam.questions]',
      () async {
        final exam = const ExamModel.empty().copyWith(
          questions: [const ExamQuestionModel.empty()],
        );

        await firestore
            .collection('courses')
            .doc(exam.courseId)
            .set(
              CourseModel.empty().copyWith(id: exam.courseId).toMap(),
            );

        await remoteDataSource.uploadExam(exam);

        final examDocs = await firestore
            .collection('courses')
            .doc(exam.courseId)
            .collection('exams')
            .get();

        expect(examDocs.docs, isNotEmpty);
        final examModel = ExamModel.fromMap(examDocs.docs.first.data());
        expect(examModel.courseId, exam.courseId);

        final questionDocs = await firestore
            .collection('courses')
            .doc(examModel.courseId)
            .collection('exams')
            .doc(examModel.id)
            .collection('questions')
            .get();

        expect(questionDocs.docs, isNotEmpty);
        final questionModel = ExamQuestionModel.fromMap(
          questionDocs.docs.first.data(),
        );
        expect(questionModel.courseId, exam.courseId);
        expect(questionModel.examId, examModel.id);
      },
    );
  });
  group('getExamQuestions', () {
    test('should return the questions of the given exam', () async {
      final exam = const ExamModel.empty().copyWith(
        questions: [const ExamQuestionModel.empty()],
      );

      await firestore
          .collection('courses')
          .doc(exam.courseId)
          .set(
            CourseModel.empty().copyWith(id: exam.courseId).toMap(),
          );
      await remoteDataSource.uploadExam(exam);

      final examsCollection = await firestore
          .collection('courses')
          .doc(exam.courseId)
          .collection('exams')
          .get();
      final examModel = ExamModel.fromMap(examsCollection.docs.first.data());

      final result = await remoteDataSource.getExamQuestions(examModel);

      expect(result, isA<List<ExamQuestionModel>>());
      expect(result, hasLength(1));
      expect(result.first.courseId, exam.courseId);
    });
  });
  group('getExams', () {
    test('should return the exams of the given course', () async {
      final exam = const ExamModel.empty().copyWith(
        questions: [const ExamQuestionModel.empty()],
      );

      await firestore
          .collection('courses')
          .doc(exam.courseId)
          .set(
            CourseModel.empty().copyWith(id: exam.courseId).toMap(),
          );
      await remoteDataSource.uploadExam(exam);

      final result = await remoteDataSource.getExams(exam.courseId);

      expect(result, isA<List<ExamModel>>());
      expect(result, hasLength(1));
      expect(result.first.courseId, exam.courseId);
    });
  });
  group('updateExam', () {
    test('should update the given exam', () async {
      final exam = const ExamModel.empty().copyWith(
        questions: [const ExamQuestionModel.empty()],
      );
      await firestore
          .collection('courses')
          .doc(exam.courseId)
          .set(
            CourseModel.empty().copyWith(id: exam.courseId).toMap(),
          );
      await remoteDataSource.uploadExam(exam);

      final examsCollection = await firestore
          .collection('courses')
          .doc(exam.courseId)
          .collection('exams')
          .get();
      final examModel = ExamModel.fromMap(examsCollection.docs.first.data());
      await remoteDataSource.updateExam(examModel.copyWith(timeLimit: 100));

      final updatedExam = await firestore
          .collection('courses')
          .doc(exam.courseId)
          .collection('exams')
          .doc(examModel.id)
          .get();
      expect(updatedExam.data(), isNotEmpty);
      final updatedExamModel = ExamModel.fromMap(updatedExam.data()!);
      expect(updatedExamModel.courseId, exam.courseId);
      expect(updatedExamModel.timeLimit, 100);
    });
  });
  group('submitExam', () {
    test(
      'should submit the given exam',
      () async {
        final userExam = UserExamModel.empty().copyWith(
          totalQuestions: 2,
          answers: [const UserChoiceModel.empty()],
        );
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .set(
              const LocalUserModel.empty()
                  .copyWith(uid: auth.currentUser!.uid, points: 1)
                  .toMap(),
            );

        await remoteDataSource.submitExam(userExam);

        final submittedExam = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('courses')
            .doc(userExam.courseId)
            .collection('exams')
            .doc(userExam.examId)
            .get();

        expect(submittedExam.data(), isNotEmpty);
        final submittedExamModel = UserExamModel.fromMap(submittedExam.data()!);
        expect(submittedExamModel.courseId, userExam.courseId);

        final userDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get();

        expect(userDoc.data(), isNotEmpty);
        final userModel = LocalUserModel.fromMap(userDoc.data()!);
        expect(userModel.points, 51);

        expect(userModel.enrolledCourseIds, contains(userExam.courseId));
      },
    );
  });
  group('getUserCourseExams', () {
    test(
      'should return the exams of the given course',
      () async {
        final exam = UserExamModel.empty();
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .set(
              const LocalUserModel.empty()
                  .copyWith(uid: auth.currentUser!.uid, points: 1)
                  .toMap(),
            );
        await remoteDataSource.submitExam(exam);

        final result = await remoteDataSource.getUserCourseExams(exam.courseId);

        expect(result, isA<List<UserExamModel>>());
        expect(result, hasLength(1));
        expect(result.first.courseId, exam.courseId);
      },
    );
  });
  group('getUserExams', () {
    test('should return the exams of the current user', () async {
      final exam = UserExamModel.empty();
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .set(
            const LocalUserModel.empty()
                .copyWith(uid: auth.currentUser!.uid, points: 1)
                .toMap(),
          );
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('courses')
          .doc(exam.courseId)
          .set(
            CourseModel.empty().copyWith(id: exam.courseId).toMap(),
          );
      await remoteDataSource.submitExam(exam);

      final result = await remoteDataSource.getUserExams();

      expect(result, isA<List<UserExamModel>>());
      expect(result, hasLength(1));
      expect(result.first.courseId, exam.courseId);
    });
  });
}
