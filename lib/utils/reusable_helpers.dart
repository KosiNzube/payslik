import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReusableHelpers {

  static void showErrorToast(
      String message, {
        Toast toastLength = Toast.LENGTH_LONG,
        ToastGravity gravity = ToastGravity.TOP
      }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }


  static void showCustomErrorToast(
      BuildContext context,
      String message, {
        String headerText = '',
        int durationInSeconds = 5,
        TextAlign textAlign = TextAlign.left,
      }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header text
                  if(headerText.isNotEmpty)
                    Text(
                      headerText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4.0), // Space between header and message

                  // Message text
                  Text(
                    message,
                    textAlign: textAlign,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(Duration(seconds: durationInSeconds), () {
      overlayEntry.remove();
    });
  }


  static void showSuccessToast(
      String message, {
        Toast toastLength = Toast.LENGTH_LONG,
        ToastGravity gravity = ToastGravity.TOP
      }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }


  static void showAlertPopUp(
      BuildContext context,
      String title, {
        String message = "",
        String buttonText = "OK"
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }


  static String shortenTextLength(String text, {int maxLength=30}) {
    return text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;
  }


  static String formatDateReadble(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('MMMM d, yyyy h:mm a').format(dateTime);
  }


}

