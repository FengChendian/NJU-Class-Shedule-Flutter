import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../generated/l10n.dart';
import '../../Models/CourseModel.dart';
import '../../Models/ScheduleModel.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Components/Dialog.dart';
import '../../Components/Toast.dart';

import 'Widgets/CourseDetailDialog.dart';
import 'Widgets/HideFreeCourseDialog.dart';
import 'Widgets/CourseDeleteDialog.dart';
import 'Widgets/CourseWidget.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = new CourseProvider();
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [];
  List<Course> freeCourses = [];

  refreshClasses(int tableId, int nowWeek) async {
    List allCoursesMap = await courseProvider.getAllCourses(tableId);
    List<Course> allCourses = [];
    for (Map<String, dynamic> courseMap in allCoursesMap) {
      allCourses.add(new Course.fromMap(courseMap));
    }
    ScheduleModel scheduleModel = new ScheduleModel(allCourses, nowWeek);
    scheduleModel.init();

    activeCourses = scheduleModel.activeCourses;
    hideCourses = scheduleModel.hideCourses;
    multiCourses = scheduleModel.multiCourses;
    freeCourses = scheduleModel.freeCourses;
  }

  Future<List<Widget>?> getClassesWidgetList(
      BuildContext context, double height, double width, int nowWeek) async {
    List colorPool = await ColorPool.getColorPool();
    List<Widget> result = List.generate(
            hideCourses.length,
            (int i) => CourseWidget(
                  hideCourses[i],
                  Config.HIDE_CLASS_COLOR,
                  height,
                  width,
                  false,
                  false,
                  () => showClassDialog(context, hideCourses[i], false),
                  () => showDeleteDialog(
                    context,
                    hideCourses[i],
                  ),
                )) +
        List.generate(
            activeCourses.length,
            (int i) => CourseWidget(
                  activeCourses[i],
                  activeCourses[i].getColor(colorPool)!,
                  height,
                  width,
                  true,
                  false,
                  () => showClassDialog(context, activeCourses[i], true),
                  () => showDeleteDialog(context, activeCourses[i]),
                )) +
        List.generate(
            multiCourses.length,
            (int i) => CourseWidget(
                multiCourses[i][0],
                multiCourses[i][0].getColor(colorPool)!,
                height,
                width,
                isThisWeek(multiCourses[i][0], nowWeek),
                true,
                () => showMultiClassDialog(context, i, nowWeek),
                () => showDeleteDialog(context, multiCourses[i][0])));
    return result;
  }

  Future<bool> showAfterImport(BuildContext context) async {
    Dio dio = new Dio();
    String url = Url.UPDATE_ROOT + '/complete.json';
    Response response = await dio.get(url);
    String welcome_title = '';
    String welcome_content = '';
    int delay_seconds = Config.DONATE_DIALOG_DELAY_SECONDS;
    if (response.statusCode == HttpStatus.ok) {
      welcome_title = response.data['title'];
      welcome_content = response.data['content_html'];
      delay_seconds = response.data['delay'];
      bool isSameWeek = await WeekUtil.isSameWeek(
          (response.data['semester_start_monday']), 1);
      if (!isSameWeek)
        await changeWeek(context, response.data['semester_start_monday']);
    } else {
      welcome_title = S.of(context).welcome_title;
      welcome_content = S.of(context).welcome_content_html;
    }
    Timer(Duration(seconds: delay_seconds), () {
      showDonateDialog(context, welcome_title, welcome_content);
    });
    return true;
  }

  void showDonateDialog(BuildContext context, String welcome_title,
      String welcome_content) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        // builder: (context) => mDialog(
        //       welcome_title,
        //       SingleChildScrollView(child: Text(welcome_content)),
        //       <Widget>[
        //         Column(
        //           mainAxisSize: MainAxisSize.min,
        //           children: <Widget>[
        //             TextButton(
        //                 // textColor: Theme.of(context).primaryColor,
        //                 child: Text(S.of(context).love_and_donate),
        //                 onPressed: () async {
        //                   if (Platform.isIOS)
        //                     launch(Url.URL_APPLE);
        //                   else if (Platform.isAndroid) launch(Url.URL_ANDROID);
        //                   Navigator.of(context).pop();
        //                 }),
        //             TextButton(
        //                 // textColor: Theme.of(context).primaryColor,
        //                 child: Text(S.of(context).bug_and_report),
        //                 onPressed: () {
        //                   if (Platform.isIOS)
        //                     launch(Url.QQ_GROUP_APPLE_URL);
        //                   else if (Platform.isAndroid)
        //                     launch(Url.QQ_GROUP_ANDROID_URL);
        //                   Navigator.of(context).pop();
        //                 }),
        //             TextButton(
        //                 // textColor: Colors.grey,
        //                 child: Text(S.of(context).love_but_no_money),
        //                 onPressed: () async {
        //                   Navigator.of(context).pop();
        //                 }),
        //           ],
        //         )
        //       ],
        //     ));
        builder: (context) => mDialog(
              welcome_title,
              SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                    Html(data: welcome_content),
                    TextButton(
                        style: ButtonStyle(alignment: Alignment.centerRight),
                        child: Text(S.of(context).love_and_donate,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor)),
                        onPressed: () async {
                          if (Platform.isIOS)
                            launch(Url.URL_APPLE);
                          else if (Platform.isAndroid) launch(Url.URL_ANDROID);
                          Navigator.of(context).pop();
                        }),
                    TextButton(
                        style: ButtonStyle(alignment: Alignment.centerRight),
                        child: Text(S.of(context).bug_and_report,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor)),
                        onPressed: () {
                          if (Platform.isIOS)
                            launch(Url.QQ_GROUP_APPLE_URL);
                          else if (Platform.isAndroid)
                            launch(Url.QQ_GROUP_ANDROID_URL);
                          Navigator.of(context).pop();
                        }),
                    TextButton(
                        style: ButtonStyle(alignment: Alignment.centerRight),
                        child: Text(S.of(context).love_but_no_money,
                            style: TextStyle(color: Colors.grey)),
                        onPressed: () async {
                          Navigator.of(context).pop();
                        }),
                  ])),
              <Widget>[],
            ));
  }

  Future<bool> changeWeek(
      BuildContext context, String semester_start_monday) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => mDialog(S.of(context).fix_week_dialog_title,
          Text(S.of(context).fix_week_dialog_content), <Widget>[
        FlatButton(
          textColor: Colors.grey,
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
            textColor: Theme.of(context).primaryColor,
            child: Text(S.of(context).ok),
            onPressed: () async {
              await WeekUtil.initWeek(semester_start_monday, 1);
              ScopedModel.of<MainStateModel>(context).refresh();
              Toast.showToast(S.of(context).fix_week_toast_success, context);
              Navigator.of(context).pop(true);
            }),
      ]),
    );
    return true;
  }

  showClassDialog(BuildContext context, Course course, bool isActive) {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return CourseDetailDialog(course, isActive, () {
            Navigator.of(context).pop();
          });
        });
  }

  showMultiClassDialog(BuildContext context, int i, int nowWeek) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          // 设计失误，其实应该把是不是当前周传进来的

          return Swiper(
            itemBuilder: (BuildContext context, int index) {
              return CourseDetailDialog(
                  multiCourses[i][index],
                  isThisWeek(multiCourses[i][index], nowWeek),
                  () => Navigator.of(context).pop());
            },
            itemCount: multiCourses[i].length,
            pagination: new SwiperPagination(
                margin: new EdgeInsets.only(bottom: 100),
                builder: new DotSwiperPaginationBuilder(
                    color: Colors.grey,
                    activeColor: Theme.of(context).primaryColor)),
            viewportFraction: 1,
            scale: 1,
          );
        });
  }

  showFreeClassDialog(BuildContext context, int nowWeek) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {

          return Swiper(
            itemBuilder: (BuildContext context, int index) {
              return CourseDetailDialog(
                  freeCourses[index],
                  isThisWeek(freeCourses[index], nowWeek),
                      () => Navigator.of(context).pop());
            },
            itemCount: freeCourses.length,
            pagination: new SwiperPagination(
                margin: new EdgeInsets.only(bottom: 100),
                builder: new DotSwiperPaginationBuilder(
                    color: Colors.grey,
                    activeColor: Theme.of(context).primaryColor)),
            loop: freeCourses.length > 1,
            viewportFraction: 1,
            scale: 1,
          );
        });
  }

  showDeleteDialog(BuildContext context, Course course) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CourseDeleteDialog(course);
      },
    );
  }

  showHideFreeCourseDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return HideFreeCourseDialog();
      },
    );
  }

  bool isThisWeek(Course course, int nowWeek) {
    List weeks = json.decode(course.weeks!);
    return weeks.contains(nowWeek);
  }

//TEST: 测试用函数
//  Future insertMockData() async {
//    await courseProvider.insert(new Course(
//        0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
//        color: '#8AD297', classroom: 'QAQ'));
//    await courseProvider.insert(new Course(
//        0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
//        color: '#F9A883', classroom: '仙林校区不知道哪个教室'));
//    await courseProvider.insert(new Course(
//        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
//        color: '#F9A883', classroom: 'QAQ'));
//  }
}
