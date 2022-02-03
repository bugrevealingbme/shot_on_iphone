import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shot_on_iphone/overlay.dart';
import 'package:shot_on_iphone/settings.dart';
import 'package:shot_on_iphone/watermark/watermark.dart';
import 'package:shot_on_iphone/widgets.dart';
import 'package:shot_on_iphone/painter/image_painter.dart' as painter;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //only portrait
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  //Remove this method to stop OneSignal Debugging
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  OneSignal.shared.setAppId("e5a9154f-86d0-47df-b1b2-8448b36600e8");

  // The promptForPushNotificationsWithUserResponse function will show the iOS push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.shared
      .promptUserForPushNotificationPermission()
      .then((accepted) {});

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  int geted = 4;

  setLocale(Locale value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = value;
    });
    prefs.setString('langCode', value.toString());
    await AppLocalizations.delegate.load(_locale);
  }

  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  getState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String deviceLanguage = Platform.localeName.substring(0, 2);
    setState(() {
      if (prefs.getString('langCode') != null) {
        _locale = Locale(prefs.getString('langCode').toString());
      } else {
        prefs.setString('langCode', deviceLanguage);
      }

      var _darkValue = prefs.getString("darkAmk") ?? "device";
      if (_darkValue == "light") {
        _themeMode = ThemeMode.light;
      } else if (_darkValue == "dark") {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      debugShowCheckedModeBanner: false,
      title: 'Shot on iPhone',
      themeMode: _themeMode,
      theme: ThemeData(
        fontFamily: 'Raleway',
        backgroundColor: const Color(0xfff3f3f3),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xfff3f3f3),
              statusBarIconBrightness: Brightness.dark),
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Raleway',
        brightness: Brightness.dark,
        backgroundColor: const Color(0xff000000),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xff000000),
              statusBarIconBrightness: Brightness.light),
        ),
      ),
      home: const MyHomePage(title: 'Shot on iPhone'),
    );
  }
}

_showDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Column(
            /*mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,*/
            children: <Widget>[
              Text("Shot By"),
            ],
          ),
          content: Card(
            margin: const EdgeInsets.only(top: 15),
            color: Colors.transparent,
            elevation: 0.0,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: shotedby,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "By",
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () {
                shottext = shotedby.text;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final picker = ImagePicker();
late Future<File?> pickedFile;
late File pickedimage;
bool secildi = false, gsecildi = false;
late ui.Image _image;
var _logo;
final shotedby = TextEditingController();
String shottext = "Your Name";
double wSize = 1;
int wmarkPosition = 0;

class _MyHomePageState extends State<MyHomePage> {
  late GridGallery gridGallery;
  bool appleLogo = true;
  List positions = ['Bottom Left', 'Top Left'];

  @override
  void initState() {
    super.initState();
    gridGallery = GridGallery(
      callback: callback,
    );

    loadImage("assets/images/apple_logo_grey.png").then((value) {
      setState(() {
        _logo = value;
        return _logo;
      });
    });

    if (!secildi) {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        gallerySheet(context);
      });
    }
  }

  @override
  void dispose() {
    shotedby.dispose();
    super.dispose();
  }

  void callback(Future<File?> pickedFile) {
    setState(() {
      pickedFile = pickedFile;
    });
  }

  Future loadImage(String asset) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  Future _fileToIMG(File file) async {
    var codec = await ui.instantiateImageCodec(file.readAsBytesSync());
    var frame = await codec.getNextFrame();

    var un8 = await file.readAsBytesSync();

    return [frame.image, un8];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const SettingsPage()));
              },
              icon: const Icon(
                Icons.settings_outlined,
                size: 26.0,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                if (secildi || gsecildi) ...[
                  gsecildi
                      ? imageToWater(pickedimage)
                      : FutureBuilder<File?>(
                          future: pickedFile,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const SizedBox(
                                  height: 200,
                                  child: CircularProgressIndicator());
                            }

                            final file = snapshot.data;
                            if (file == null) return Container();

                            return imageToWater(file);
                          },
                        ),
                ] else ...[
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: CupertinoButton(
                        child: const Text(
                          'Change Photo',
                        ),
                        onPressed: () {
                          gallerySheet(context);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                settingsList(
                    context,
                    const Text(
                      "Apple Logo",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    CupertinoSwitch(
                      value: appleLogo,
                      onChanged: (bool newValue) {
                        setState(() {
                          appleLogo = newValue;
                        });
                      },
                    )),
                settingsList(
                    context,
                    const Text(
                      "Shoted By",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    /*ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      label: Text(shottext),
                      onPressed: () {},
                    )*/
                    TextButton.icon(
                      onPressed: () {
                        _showDialog(context);
                      },
                      label: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      icon: Text(shottext),
                    )),
                /*settingsList(
                    context,
                    const Text(
                      "iPhone Model",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    DropdownButton<dynamic>(
                      borderRadius: BorderRadius.circular(10),
                      value: "13",
                      onChanged: (newValue) {
                        setState(() {
                          wmarkPosition = newValue.toString();
                        });
                      },
                      items: <String>['13', '12', '11', '6S']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem(
                          value: value.toString(),
                          child: SizedBox(
                            width: 100,
                            child: Text(
                              value.toString(),
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        );
                      }).toList(),
                    )),*/
                /*settingsList(
                  context,
                  const Text(
                    "Size",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                      value: wSize * 100,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$wSize',
                      onChanged: (value) {
                        setState(() {
                          wSize = value / 100;
                        });
                      }),
                ),*/
                settingsList(
                    context,
                    const Text(
                      "Position",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        watermarkPositionSheet(context);
                      },
                      label: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      icon: Text(positions[wmarkPosition].toString()),
                    )),
                const SizedBox(height: 50),
              ]),
        ),
      ),
    );
  }

  Future<void> watermarkPositionSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 20),
            SizedBox(
              width: 70,
              height: 5,
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xffcccccc),
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  padding: const EdgeInsets.all(0),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  primary: false,
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                      width: 1,
                                      color: wmarkPosition == index
                                          ? Colors.green
                                          : Colors.transparent)),
                              padding: EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: index == 0 ? 90 : 20,
                                  bottom: index == 0 ? 20 : 90),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                verticalDirection: VerticalDirection.down,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset(
                                        "assets/images/apple_logo_grey.png"),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    "Shot on iPhone",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerRight,
                            ),
                            const SizedBox(height: 10),
                            Text(positions[index].toString(),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: wmarkPosition == index
                                        ? Colors.green
                                        : null)),
                          ],
                        ), //              <--- Put this on bottom
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                wmarkPosition = index;
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }),
            ),
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }

  FutureBuilder imageToWater(File file) {
    return FutureBuilder(
        future: _fileToIMG(file),
        builder: (context, AsyncSnapshot snapshot) {
          return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            ui.Image image = snapshot.data[0]!;
            Uint8List imageAs8 = snapshot.data[1]!;

            double ratio = image.height / image.width;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  child: Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      image: DecorationImage(
                          image: MemoryImage(imageAs8.buffer.asUint8List()),
                          fit: BoxFit.cover,
                          scale: 1,
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height / 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxWidth * ratio,
                          child: CustomPaint(
                            painter: painter.ImagePainter(
                                image: image,
                                text: shottext,
                                style: const TextStyle(
                                  fontSize: 21,
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                ),
                                logo: _logo,
                                showlogo: appleLogo,
                                position: wmarkPosition),
                            willChange: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          child: const Text(
                            'Change Photo',
                          ),
                          onPressed: () {
                            gallerySheet(context);
                          },
                        ),
                        CupertinoButton(
                          /*borderRadius: BorderRadius.circular(15),
                    color: Colors.white,*/
                          child: const Text(
                            'Save Photo',
                          ),
                          onPressed: () {
                            takeSnapshot(image);

                            Navigator.of(context)
                                .push(TutorialOverlay(saved: false));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }

  Future<void> gallerySheet(BuildContext context) {
    return showModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      context: context,
      isScrollControlled: true,
      enableDrag: secildi ? true : false,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 70,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xffcccccc),
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        widthFactor: double.infinity,
                        child: OutlinedButton(
                            onPressed: () async {
                              final picked = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (picked == null) {
                                return;
                              }
                              final image = File(picked.path);

                              setState(() {
                                pickedimage = image;
                                gsecildi = true;
                                Navigator.of(context).pop();
                              });
                            },
                            child: Text("Choose from Gallery")),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: crtLabel("RECENT"),
                      ),
                      GridGallery(
                        callback: callback,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void takeSnapshot(image) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    Watermark.draw(
        canvas,
        image,
        shottext,
        TextStyle(fontSize: 21, color: Color.fromRGBO(255, 255, 255, 1)),
        Size(image.width.roundToDouble(), image.height.roundToDouble()),
        _logo,
        appleLogo,
        wmarkPosition);

    ui.Image pic =
        await recorder.endRecording().toImage(image.width, image.height);
    ByteData? data = await pic.toByteData(format: ui.ImageByteFormat.png);

    if (await Permission.storage.request().isGranted) {
      Directory doc = await getApplicationDocumentsDirectory();
      File tmp = File('${doc.path}/shot_iphone' +
          DateTime.now().toString() +
          '.png'); //DateTime.now().toString()
      tmp.writeAsBytesSync(data!.buffer.asUint8List());
      await GallerySaver.saveImage(tmp.path, albumName: 'watermark')
          .then((value) {
        Navigator.pop(context);
        Navigator.of(context).push(TutorialOverlay(saved: true));
      }).catchError((e) {});
    }
  }
}

Card settingsList(BuildContext context, gtitle, gtrailing) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: ListTile(title: gtitle, trailing: gtrailing),
    ),
  );
}

class GridGallery extends StatefulWidget {
  final ScrollController? scrollCtr;
  Function callback;

  GridGallery({
    required this.callback,
    Key? key,
    this.scrollCtr,
  }) : super(key: key);

  @override
  _GridGalleryState createState() => _GridGalleryState();
}

class _GridGalleryState extends State<GridGallery> {
  final List<Widget> _mediaList = [];
  int currentPage = 0;
  int? lastPage;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  _fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      // success

      //load the album list
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          onlyAll: true, type: RequestType.image);
      List<AssetEntity> media = await albums[0].getAssetListPaged(
        currentPage,
        60,
      ); //preloading files
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder(
            future: asset.thumbDataWithSize(200, 200), //resolution of thumbnail
            builder:
                (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      Navigator.of(context).pop();
                      pickedFile = asset.file;
                      secildi = true;
                      widget.callback(pickedFile);
                    });
                  },
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (asset.type == AssetType.video)
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 5, bottom: 5),
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Container();
            },
          ),
        );
      }
      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        _handleScrollEvent(scroll);
        return false;
      },
      child: GridView.builder(
          controller: widget.scrollCtr,
          itemCount: _mediaList.length,
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          primary: false,
          scrollDirection: Axis.vertical,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          itemBuilder: (BuildContext context, int index) {
            return Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.white)),
                child: _mediaList[index]);
          }),
    );
  }
}
