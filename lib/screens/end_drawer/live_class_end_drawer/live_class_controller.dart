// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jo_students/check_user/check_user_request.dart';
import 'package:jo_students/check_user/check_user_response.dart';
import 'package:jo_students/configuration/api_end_point.dart';
import 'package:jo_students/configuration/constant_values.dart';
import 'package:jo_students/screens/http_wrapper/http_wrapper.dart';
import 'package:jo_students/utils/helpers/general.dart';
import 'package:jo_students/utils/helpers/progress_hud.dart';
import 'package:oktoast/oktoast.dart';

import 'live_class_request.dart';
import 'live_class_response.dart';


enum ApiStatus { loading, empty, error, success }

class LiveClassController extends GetxController {
  var liveClasses = <LiveClassResponse>[].obs;
  var filteredLiveClasses = <LiveClassResponse>[].obs;
  var status = ApiStatus.loading.obs;


  @override
  void onInit() {
    super.onInit();
    initController();
  }

  Future<void> initController() async {
    String loginTrx = await General.getPrefString(ConstantValues.MSG, "");
    await checkUser(loginTrx: loginTrx);
  }

  checkUser({required String loginTrx}) async {
    try {
      CheckUserRequest request = CheckUserRequest(loginTrx: loginTrx);
      ApiResponse? response = await HttpWrapper(
        context: Get.context!,
        url: ApiEndPoint.CHECK_USER_URL,
        body: request.toJson(),
      ).post();

      if (response != null && response.body != null) {
        CheckUserResponse checkUserResponse =
        CheckUserResponse.fromRawJson(utf8.decode(response.body!));
        if (response.statusCode == 200) {
          int? semesterId = checkUserResponse.semesterid;
          int? classId = checkUserResponse.classid;
          fetchLiveClassesFromApi(semesterId, classId);
        }
      }
    } catch (e) {
      showToast("'No internet connection available'",
          backgroundColor: Colors.red, duration: const Duration(seconds: 3));
    } finally {
      ProgressHud.shared.stopLoading();
    }
  }

  fetchLiveClassesFromApi(int? semesterID, int? classID) async {
    if (semesterID == null || classID == null) {
      return;
    }

    try {
      LiveClassRequest request = LiveClassRequest(
          semesterId: semesterID, classId: classID);
      ApiResponse? response = await HttpWrapper(
        context: Get.context,
        url: ApiEndPoint.LIVE_CLASSES_URL,
        body: request.toJson(),
      ).post();

      if (response != null && response.statusCode == 200) {
        if (response.body != null) {
          List data = jsonDecode(utf8.decode(response.body!));
          if (data.isEmpty) {
            status.value = ApiStatus.empty;
          } else {
            List<LiveClassResponse> liveClassList = data
                .map((item) => LiveClassResponse.fromJson(item))
                .toList();


            liveClasses.value = liveClassList;
            filteredLiveClasses.value = liveClasses;


            liveClassList.sort((a, b) => b.liveSessionId.compareTo(a.liveSessionId));

            status.value = ApiStatus.success;
          }
        }
      }
    } catch (e) {
      status.value = ApiStatus.error;
      showToast(" No internet connection available",
          backgroundColor: Colors.red, duration: const Duration(seconds: 3));
    }
  }


  void filterLiveClasses(String query) {
    if (query.isEmpty) {
      filteredLiveClasses.value = liveClasses;
    } else {
      filteredLiveClasses.value = liveClasses.where((liveClass) {
        return liveClass.liveSubjectTitle
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    }
  }

  void resetFilter() {
    filteredLiveClasses.value = liveClasses;
  }

  bool get isLoading => status.value == ApiStatus.loading;

  bool get isEmpty => status.value == ApiStatus.empty;

  bool get isError => status.value == ApiStatus.error;

  bool get isSuccess => status.value == ApiStatus.success;
}


