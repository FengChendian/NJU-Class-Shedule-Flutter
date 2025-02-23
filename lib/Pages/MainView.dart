import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:package_info/package_info.dart';
import 'CourseTable/CourseTableView.dart';
import '../Utils/UpdateUtil.dart';
import '../Utils/PrivacyUtil.dart';
import '../Utils/States/MainState.dart';
import '../Components/Dialog.dart';
import '../Resources/Url.dart';

class MainView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    checkFirstTime(context);
//    showUpdateDialog(info, context);
    UpdateUtil updateUtil = new UpdateUtil();
    updateUtil.checkUpdate(context, false);
    PrivacyUtil privacyUtil = new PrivacyUtil();
    privacyUtil.checkPrivacy(context, false);
    return CourseTableView();
  }

   // void checkPrivacy(BuildContext context) async {
   //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
   //   SharedPreferences sp = await SharedPreferences.getInstance();
   //   PrivacyUtil privacyUtil = new PrivacyUtil();
   //   await privacyUtil.checkUpdate(context, false);
   //   String storedVersion = sp.getString('privacyversion');
   //
   //
   //
   //   if(storedVersion == null || storedVersion != packageInfo.version)
   //     showDonateDialog(context);
   //   sp.setString("version", packageInfo.version);
   // }

//  void checkFirstTime(BuildContext context) async {
//    PackageInfo packageInfo = await PackageInfo.fromPlatform();
//    SharedPreferences sp = await SharedPreferences.getInstance();
//    String storedVersion = sp.getString('version');
//    if(storedVersion == null || storedVersion != packageInfo.version)
//      showDonateDialog(context);
//    sp.setString("version", packageInfo.version);
//  }
}
