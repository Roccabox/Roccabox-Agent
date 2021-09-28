import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roccabox_agent/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'homenav.dart';
import 'login.dart';
import 'notifications.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String id = "";
  FirebaseMessaging? auth;
  var token;
  final firestoreInstance = FirebaseFirestore.instance;

  @override
  void initState() {
    auth = FirebaseMessaging.instance;
    auth?.getToken().then((value){
      print("FirebaseToken "+value.toString());
      token = value.toString();


    }
    );
    getLoginStatus();

    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings = InitializationSettings(
        iOS: initializationSettingsIOS, android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);

    //fetchLocation();
    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      print('Running On Message');
      Map<String, dynamic>map;
      if(message.notification==null){
        if(message.data!=null){

          map = message.data;

          print("Message "+map["title"]);
          createListMap(map);
          flutterLocalNotificationsPlugin.show(
              message.hashCode,
              map["title"].toString(),
              map["body"].toString(),
              NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    channel.description,
                    color: Colors.blue,
                    playSound: true,
                    icon: '@mipmap/ic_launcher',
                    largeIcon: DrawableResourceAndroidBitmap(
                        '@mipmap/ic_launcher'),
                  )
              ));

        }


      }else {
        RemoteNotification? notification  = message.notification;

        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          createList(notification);
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    channel.description,
                    color: Colors.blue,
                    playSound: true,
                    icon: '@mipmap/ic_launcher',
                    largeIcon: DrawableResourceAndroidBitmap(
                        '@mipmap/ic_launcher'),
                  )
              ));
        }
      }
    });


    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new on message openedApp event was published');
      RemoteNotification? notification = message.notification;
      AndroidNotification? androidNotification = message.notification!.android;

      if(notification!=null && androidNotification !=null){
        createList(notification);

        //    showAlertDialog(context);
        /*       showDialog(context: context, builder:(_) {

          return AlertDialog(
            title: Text(notification.title.toString()),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.body.toString())
                ],
              ),
            ),
          );

        });*/
      }else if(message.data!=null){
        Map<String, dynamic> map = message.data;
        createListMap(map);
      }

    });


    super.initState();
  }




  Future selectNotification(String? payload) async {
/*    if (payload != null) {
      debugPrint('notification payload: $payload');
    }*/
    navigatorKey.currentState!.pushNamed('/notification');

  }
  Future onDidReceiveLocalNotification(
      int? id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          CupertinoAlertDialog(
            title: Text(title.toString()),
            content: Text(body.toString()),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Ok'),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Notifications(),
                    ),
                  );
                },
              )
            ],
          ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: SvgPicture.asset('assets/roccabox-logo.svg'),
        ),
      ),
    );
  }

  getLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    id = prefs.getString("id").toString();
    print("id :" + id + "^");


    if(id!=null){

      var documentReference = FirebaseFirestore.instance
          .collection('token')
          .doc(id.toString());

      firestoreInstance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          {
            'token': token
          },
        );
      });
    }
    Future.delayed(Duration(seconds: 2), () {
      id.toString() == "" || id.toString() == "null" || id == null
          ? Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Login()))
          : Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeNav()),
              (route) => false);
    });
  }




  Future<void> createList(RemoteNotification notification) async {
    print("ListSave");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String>? titleList = preferences.getStringList('titleList');
    List<String>? bodyList = preferences.getStringList('bodyList');
    // List<String> timeList = preferences.getStringList('timeList');
    if(titleList!=null && bodyList!=null){
      titleList.add(notification.title.toString());
      bodyList.add(notification.body.toString());
      preferences.setStringList("titleList", titleList);
      preferences.setStringList("bodyList", bodyList);
      //  preferences.setStringList("timeList", timeList);
      preferences.commit();
    }else{
      List<String> titleListNew = [];
      List<String> bodyListNew = [];

      titleListNew.add(notification.title.toString());
      bodyListNew.add(notification.body.toString());

      preferences.setStringList("titleList", titleListNew);
      preferences.setStringList("bodyList", bodyListNew);
      preferences.commit();
    }
    navigatorKey.currentState!.pushNamed('/notification');

  }


  Future<void> createListMap(Map<String, dynamic> map) async {
    print("ListSave");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String>? titleList = preferences.getStringList('titleList');
    List<String>? bodyList = preferences.getStringList('bodyList');
    // List<String> timeList = preferences.getStringList('timeList');
    if(titleList!=null && bodyList!=null){
      titleList.add(map["title"].toString());
      bodyList.add(map["body"].toString());
      preferences.setStringList("titleList", titleList);
      preferences.setStringList("bodyList", bodyList);
      //  preferences.setStringList("timeList", timeList);
      preferences.commit();
    }else{
      List<String> titleListNew = [];
      List<String> bodyListNew = [];

      titleListNew.add(map["title"].toString());
      bodyListNew.add(map["body"].toString());

      preferences.setStringList("titleList", titleListNew);
      preferences.setStringList("bodyList", bodyListNew);
      preferences.commit();
    }

  }
}
