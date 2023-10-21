
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/ui/theme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';
class NotifyHelper {
  FlutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin(); //
  String? selectedNotificationPayload;

  final BehaviorSubject<String?> selectNotificationSubject =
  BehaviorSubject<String?>();
  initializeNotification() async {
    _configureSelectNotificationSubject();
    await _configureLocalTimeZone();

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        onDidReceiveLocalNotification: onDidReceiveLocalNotification
    );
    final AndroidInitializationSettings androidInitializationSettings = new AndroidInitializationSettings("ic_launcher");
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (data) async {
          if (data != null) {
            debugPrint('Mensagem de notificação: ' + data.payload!);
          }
          selectNotificationSubject.add(data.payload);
        });
  }
  void requestIOSPermissions(
      ) {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }



  Future onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {

    showDialog(
      context: Get.context!,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title!),
        content: Text(body!),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecondScreen(payload),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  displayNotification({required String title, required String body}) async {
    print("doing test");
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name',
        importance: Importance.max, priority: Priority.high);
    var iOSPlatformChannelSpecifics = new DarwinNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Você mudou seu tema',
      'Você mudou seu tema escuro !',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }
  tz.TZDateTime _nextInstanceOfTenAM(int hour, int minutes) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minutes);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
  scheduledNotification(int hour, int minutes,Task task) async {

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id!,
      task.title,
      task.note,
      _nextInstanceOfTenAM(hour, minutes),

      const NotificationDetails(
          android: AndroidNotificationDetails('your channel id',
              'your channel name', )),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: "${task.title}|"+"${task.note}|"+"${task.startTime}|",
    );

  }
  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      debugPrint("My mensagem é "+payload!);
      await Get.to(()=>SecondScreen(payload));
    });
  }
  periodicalyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('repeating channel id',
        'repeating channel name', );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
        'repeating body', RepeatInterval.everyMinute, platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }
}

class SecondScreen extends StatefulWidget {
  SecondScreen(this.payload);

  final String? payload;

  @override
  State<StatefulWidget> createState() => SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  String? _payload;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' ${_payload.toString().split("|")[0] ?? 'No title'}'),
      ),
      body: Container(

        child: Column(
            children:[
              SizedBox(height: 40,),
              Container(
                child: Column(
                    children:[
                      Text("Olá", style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color:Color(0xFF162339)
                      ),),
                      SizedBox(
                        height: 10,
                      ),
                      Text("Você tem um novo lembrete", style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color:Colors.grey
                      ),),
                    ]

                ),
              ),
              SizedBox(height: 40,),
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  padding:const EdgeInsets.only(left: 30, right: 30, top:50),
                  margin: const EdgeInsets.only(left: 30, right: 30),
                  //child:Text('${_payload}'),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Row(
                          children: [
                            Icon(Icons.text_format,
                                size:35,
                                color:Colors.white
                            ),
                            SizedBox(width: 10,),
                            Text("Título",
                              style: TextStyle(
                                  color:Colors.white,
                                  fontSize: 30
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 20,),
                        Text('${_payload.toString().split("|")[0]??'No message'}',
                          style: TextStyle(
                              color:Colors.white,
                              fontSize: 20
                          ),
                        ),
                        SizedBox(height: 20,),
                        Row(
                          children: [
                            Icon(Icons.description,
                                size:35,
                                color:Colors.white
                            ),
                            SizedBox(width: 10,),
                            Text("Descrição",
                              style: TextStyle(
                                  color:Colors.white,
                                  fontSize: 30
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 20,),
                        Text('${_payload.toString().split("|")[1]??'No message'}',
                          style: TextStyle(
                              color:Colors.white,
                              fontSize: 20
                          ),
                        ),
                        SizedBox(height: 20,),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size:35,
                                color:Colors.white
                            ),
                            SizedBox(width: 10,),
                            Text("Data",
                              style: TextStyle(
                                  color:Colors.white,
                                  fontSize: 30
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 20,),
                        Text('${_payload.toString().split("|")[2]??'No message'}',
                          style: TextStyle(
                              color:Colors.white,
                              fontSize: 20
                          ),
                        )
                      ]
                  ),
                  decoration: BoxDecoration(
                      color:primaryClr,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(50),
                          topLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                          bottomLeft: Radius.circular(50)
                      )
                  ),
                ),
              ),
              SizedBox(height: 140,)
            ]


        ),
      ),
    );
  }
}

