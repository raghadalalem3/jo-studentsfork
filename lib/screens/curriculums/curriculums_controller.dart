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

import 'curriculums_model_request.dart';
import 'curriculums_model_response.dart';

enum ApiStatus { loading, empty, error, success }

class CurriculumsController extends GetxController {
  var curriculums = <CurriculumsModelResponse>[].obs;
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

  checkUser({required String loginTrx }) async {
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
          fetchCurriculumsFromApi(semesterId, classId);
                }
      }
    } catch (e) {
      showToast("No internet connection",
          backgroundColor: Colors.red, duration: const Duration(seconds: 3));
    } finally {
      ProgressHud.shared.stopLoading();
    }
  }

  fetchCurriculumsFromApi(int? semesterID, int? classID) async {
    if (semesterID == null || classID == null) {
      showToast("Invalid data received",
          backgroundColor: Colors.red, duration: const Duration(seconds: 3));
      return;
    }

    try {
      CurriculumsModelRequest request = CurriculumsModelRequest(
          semesterId: semesterID, classId: classID);
      ApiResponse? response = await HttpWrapper(
        context: Get.context,
        url: ApiEndPoint.CURRICULUMS_URL,
        body: request.toJson(),
      ).post();
      if (response!.statusCode == 200) {
        if (response.body != null) {
          List data = jsonDecode(utf8.decode(response.body!));
          status.value = ApiStatus.success;
          curriculums.value =
              data.map((item) => CurriculumsModelResponse.fromJson(item))
                  .toList();
        } else {
          status.value = ApiStatus.empty;
          Get.snackbar('Error', 'An error occurred while fetching data');
        }
      } else {
        status.value = ApiStatus.error;
      }
    } catch (e) {
      showToast("Something went wrong while fetching curriculums: $e",
          backgroundColor: Colors.red, duration: const Duration(seconds: 3));
    }
  }



  bool get isLoading => status.value == ApiStatus.loading;

  bool get isEmpty => status.value == ApiStatus.empty;

  bool get isError => status.value == ApiStatus.error;

  bool get isSuccess => status.value == ApiStatus.success;
}
