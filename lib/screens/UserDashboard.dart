import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:land_registration/providers/LandRegisterModel.dart';
import 'package:land_registration/constant/loadingScreen.dart';
import 'package:land_registration/screens/ChooseLandMap.dart';
import 'package:land_registration/screens/viewLandDetails.dart';
import 'package:land_registration/widget/land_container.dart';
import 'package:land_registration/widget/menu_item_tile.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:provider/provider.dart';
import '../providers/MetamaskProvider.dart';
import '../constant/constants.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:http/http.dart' as http;

class UserDashBoard extends StatefulWidget {
  const UserDashBoard({Key? key}) : super(key: key);

  @override
  _UserDashBoardState createState() => _UserDashBoardState();
}

class _UserDashBoardState extends State<UserDashBoard> {
  var model, model2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int screen = 0;
  late List<dynamic> userInfo;
  bool isLoading = true, isUserVerified = false;
  bool isUpdated = true;
  List<List<dynamic>> LandGall = [];
  String name = "";

  final _formKey = GlobalKey<FormState>();
  late String area,
      landAddress,
      landPrice,
      propertyID,
      surveyNo,
      document,
      allLatiLongi;
  List<List<dynamic>> landInfo = [];
  List<List<dynamic>> receivedRequestInfo = [];
  List<List<dynamic>> sentRequestInfo = [];
  List<dynamic> prices = [];
  List<Menu> menuItems = [
    Menu(title: 'Dashboard', icon: Icons.dashboard),
    Menu(title: 'Add Lands', icon: Icons.add_chart),
    Menu(title: 'My Lands', icon: Icons.landscape_rounded),
    Menu(title: 'Land Gallery', icon: Icons.landscape_rounded),
    Menu(title: 'My Received Request', icon: Icons.request_page_outlined),
    Menu(title: 'My Sent Land Request', icon: Icons.request_page_outlined),
    Menu(title: 'Logout', icon: Icons.logout),
  ];
  Map<String, String> requestStatus = {
    '0': 'Pending',
    '1': 'Accepted',
    '2': 'Rejected',
    '3': 'Payment Done',
    '4': 'Completed'
  };

  List<MapBoxPlace> predictions = [];
  late PlacesSearch placesSearch;
  final FocusNode _focusNode = FocusNode();
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  TextEditingController addressController = TextEditingController();

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
        builder: (context) => Positioned(
              width: 540,
              child: CompositedTransformFollower(
                link: this._layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0.0, 40 + 5.0),
                child: Material(
                  elevation: 4.0,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: List.generate(
                        predictions.length,
                        (index) => ListTile(
                              title:
                                  Text(predictions[index].placeName.toString()),
                              onTap: () {
                                addressController.text =
                                    predictions[index].placeName.toString();

                                setState(() {});
                                _overlayEntry.remove();
                                _overlayEntry.dispose();
                              },
                            )),
                  ),
                ),
              ),
            ));
  }

  Future<void> autocomplete(value) async {
    List<MapBoxPlace>? res = await placesSearch.getPlaces(value);
    if (res != null) predictions = res;
    setState(() {});
    // print(res);
    // print(res![0].placeName);
    // print(res![0].geometry!.coordinates);
    // print(res![0]);
  }

  @override
  void initState() {
    placesSearch = PlacesSearch(
      apiKey: mapBoxApiKey,
      limit: 10,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _overlayEntry = this._createOverlayEntry();
        Overlay.of(context)!.insert(_overlayEntry);
      } else {
        _overlayEntry.remove();
      }
    });
    super.initState();
  }

  getLandInfo() async {
    setState(() {
      isLoading = true;
    });
    List<dynamic> landList;
    if (connectedWithMetamask)
      landList = await model2.myAllLands();
    else
      landList = await model.myAllLands();

    List<List<dynamic>> info = [];
    List<dynamic> temp;
    for (int i = 0; i < landList.length; i++) {
      if (connectedWithMetamask)
        temp = await model2.landInfo(landList[i]);
      else
        temp = await model.landInfo(landList[i]);
      info.add(temp);
    }
    landInfo = info;
    setState(() {
      isLoading = false;
    });
    print(info);
  }

  getLandGallery() async {
    setState(() {
      isLoading = true;
    });
    List<dynamic> landList;
    if (connectedWithMetamask)
      landList = await model2.allLandList();
    else
      landList = await model.allLandList();

    List<List<dynamic>> allInfo = [];
    List<dynamic> temp;
    for (int i = 0; i < landList.length; i++) {
      if (connectedWithMetamask)
        temp = await model2.landInfo(landList[i]);
      else
        temp = await model.landInfo(landList[i]);
      allInfo.add(temp);
    }
    LandGall = allInfo;
    screen = 3;
    isLoading = false;
    print(LandGall);
    setState(() {});
  }

  getMySentRequest() async {
    SmartDialog.showLoading();
    setState(() {
      isLoading = true;
    });
    await getEthToInr();
    List<dynamic> requestList;
    if (connectedWithMetamask)
      requestList = await model2.mySentRequest();
    else
      requestList = await model.mySentRequest();
    List<List<dynamic>> allInfo = [];
    List<dynamic> temp;
    List<dynamic> tempPrice = [];
    var pri;
    for (int i = 0; i < requestList.length; i++) {
      if (connectedWithMetamask) {
        temp = await model2.requestInfo(requestList[i]);
        pri = await model2.landPrice(temp[3]);
      } else {
        temp = await model.requestInfo(requestList[i]);
        pri = await model.landPrice(temp[3]);
      }
      tempPrice.add(pri);
      allInfo.add(temp);
    }
    sentRequestInfo = allInfo;
    prices = tempPrice;
    screen = 5;
    isLoading = false;
    print(sentRequestInfo);
    SmartDialog.dismiss();
    setState(() {});
  }

  getMyReceivedRequest() async {
    setState(() {
      isLoading = true;
    });
    List<dynamic> requestList;
    if (connectedWithMetamask)
      requestList = await model2.myReceivedRequest();
    else {
      requestList = await model.myReceivedRequest();
    }
    List<List<dynamic>> allInfo = [];
    List<dynamic> temp;
    for (int i = 0; i < requestList.length; i++) {
      if (connectedWithMetamask)
        temp = await model2.requestInfo(requestList[i]);
      else
        temp = await model.requestInfo(requestList[i]);
      allInfo.add(temp);
    }
    receivedRequestInfo = allInfo;
    screen = 4;
    isLoading = false;
    print(receivedRequestInfo);
    setState(() {});
  }

  Future<void> getProfileInfo() async {
    // setState(() {
    //   isLoading = true;
    // });
    if (connectedWithMetamask)
      userInfo = await model2.myProfileInfo();
    else
      userInfo = await model.myProfileInfo();
    name = userInfo[1];
    setState(() {
      isLoading = false;
    });
    print(userInfo);
  }

  String docuName = "Adhar/Pan (.jpg,.pdf)";
  late PlatformFile documentFile;
  String cid = "", docUrl = "";
  bool isFilePicked = false;

  pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf'],
    );

    if (result != null) {
      isFilePicked = true;
      docuName = result.files.single.name;
      documentFile = result.files.first;
    }
    setState(() {});
  }

  Future<bool> uploadDocument() async {
    String url = "https://api.nft.storage/upload";
    var header = {
      "Authorization":
          "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDJmNGUwQTQwNTI4MkMyMDNkZDBEZmY2NUNlMkUwRTYyQUNCODFDRWUiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTYzNzkwNzQxNjEwNSwibmFtZSI6ImxhbmRfZG9jdW1lbnQifQ.5ReEuIxsDhWxOLa2lVe9n-B2PUjdEkwJ5jLsBGdBDGA"
    };

    if (isFilePicked) {
      try {
        final response = await http.post(Uri.parse(url),
            headers: header, body: documentFile.bytes);
        var data = jsonDecode(response.body);
        //print(data);
        if (data['ok']) {
          cid = data["value"]["cid"];
          docUrl = "https://" + cid + ".ipfs.dweb.link";
          print(docUrl);
          return true;
        }
      } catch (e) {
        print(e);
        showToast("Something went wrong,while document uploading",
            context: context, backgroundColor: Colors.red);
      }
    } else {
      showToast("Choose Document",
          context: context, backgroundColor: Colors.red);
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    model = Provider.of<LandRegisterModel>(context);
    model2 = Provider.of<MetaMaskProvider>(context);
    if (isUpdated) {
      getProfileInfo();
      isUpdated = false;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF272D34),
        leading: isDesktop
            ? Container()
            : GestureDetector(
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.menu,
                    color: Colors.white,
                  ), //AnimatedIcon(icon: AnimatedIcons.menu_arrow,progress: _animationController,),
                ),
                onTap: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),
        title: const Text('User Dashboard'),
      ),
      drawer: drawer2(),
      drawerScrimColor: Colors.transparent,
      body: Row(
        children: [
          isDesktop ? drawer2() : Container(),
          // Expanded(
          //   child: Column(
          //     children: [Text('Welcome')],
          //   ),
          // ),
          if (screen == 0)
            Center(widthFactor: isDesktop ? 2 : 1, child: userProfile())
          else if (screen == 1)
            addLand()
          else if (screen == 2)
            myLands()
          else if (screen == 3)
            LandGallery()
          else if (screen == 4)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: receivedRequest(),
              ),
            )
          else if (screen == 5)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: sentRequest(),
              ),
            )
        ],
      ),
    );
  }

  Widget sentRequest() {
    return ListView.builder(
      itemCount: sentRequestInfo == null ? 1 : sentRequestInfo.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            children: [
              const Divider(
                height: 15,
              ),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                    child: Text(
                      'Land Id',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                      child: Center(
                        child: Text('Owner Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      flex: 5),
                  Expanded(
                    child: Center(
                      child: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 3,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Price(in ₹)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Make Payment',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  )
                ],
              ),
              const Divider(
                height: 15,
              )
            ],
          );
        }
        index -= 1;
        List<dynamic> data = sentRequestInfo[index];
        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text((index + 1).toString()),
                flex: 1,
              ),
              Expanded(child: Center(child: Text(data[3].toString())), flex: 1),
              Expanded(
                  child: Center(
                    child: Text(data[1].toString()),
                  ),
                  flex: 5),
              Expanded(
                  child: Center(
                    child: Text(requestStatus[data[4].toString()].toString()),
                  ),
                  flex: 3),
              Expanded(
                  child: Center(
                    child: Text(prices[index].toString()),
                  ),
                  flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.green),
                        onPressed: data[4].toString() != '1'
                            ? null
                            : () async {
                                _paymentDialog(
                                    data[2],
                                    data[1],
                                    prices[index].toString(),
                                    double.parse(prices[index].toString()) /
                                        ethToInr,
                                    ethToInr,
                                    data[0]);
                                // SmartDialog.showLoading();
                                // try {
                                //   //await model.rejectRequest(data[0]);
                                //   //await getMyReceivedRequest();
                                // } catch (e) {
                                //   print(e);
                                // }
                                //
                                // //await Future.delayed(Duration(seconds: 2));
                                // SmartDialog.dismiss();
                              },
                        child: const Text('Make Payment')),
                  ),
                  flex: 2),
            ],
          ),
        );
      },
    );
  }

  Widget receivedRequest() {
    return ListView.builder(
      itemCount:
          receivedRequestInfo == null ? 1 : receivedRequestInfo.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            children: [
              const Divider(
                height: 15,
              ),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                    child: Text(
                      'Land Id',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                      child: Center(
                        child: Text('Buyer Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      flex: 5),
                  Expanded(
                    child: Center(
                      child: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 3,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Payment Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Reject',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  )
                ],
              ),
              const Divider(
                height: 15,
              )
            ],
          );
        }
        index -= 1;
        List<dynamic> data = receivedRequestInfo[index];
        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text((index + 1).toString()),
                flex: 1,
              ),
              Expanded(child: Center(child: Text(data[3].toString())), flex: 1),
              Expanded(
                  child: Center(
                    child: Text(data[2].toString()),
                  ),
                  flex: 5),
              Expanded(
                  child: Center(
                    child: Text(requestStatus[data[4].toString()].toString()),
                  ),
                  flex: 3),
              Expanded(child: Center(child: Text(data[5].toString())), flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(primary: Colors.redAccent),
                        onPressed: data[4].toString() != '0'
                            ? null
                            : () async {
                                SmartDialog.showLoading();
                                try {
                                  if (connectedWithMetamask)
                                    await model2.rejectRequest(data[0]);
                                  else
                                    await model.rejectRequest(data[0]);
                                  await getMyReceivedRequest();
                                } catch (e) {
                                  print(e);
                                }

                                //await Future.delayed(Duration(seconds: 2));
                                SmartDialog.dismiss();
                              },
                        child: const Text('Reject')),
                  ),
                  flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.greenAccent),
                        onPressed: data[4].toString() != '0'
                            ? null
                            : () async {
                                SmartDialog.showLoading();
                                try {
                                  if (connectedWithMetamask)
                                    await model2.acceptRequest(data[0]);
                                  else
                                    await model.acceptRequest(data[0]);
                                  await getMyReceivedRequest();
                                } catch (e) {
                                  print(e);
                                }

                                //await Future.delayed(Duration(seconds: 2));
                                SmartDialog.dismiss();
                              },
                        child: const Text('Accept')),
                  ),
                  flex: 2),
            ],
          ),
        );
      },
    );
  }

  Widget LandGallery() {
    if (isLoading) return const CircularProgressIndicator();
    return Center(
      child: Container(
        width: isDesktop ? 900 : width,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          scrollDirection: Axis.vertical,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisExtent: 440,
              crossAxisCount: isDesktop ? 2 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20),
          itemCount: LandGall.length,
          itemBuilder: (context, index) {
            return landWid2(
                LandGall[index][10],
                LandGall[index][1].toString(),
                LandGall[index][2].toString(),
                LandGall[index][3].toString(),
                LandGall[index][9] == userInfo[0],
                LandGall[index][8], () async {
              SmartDialog.showLoading();
              try {
                if (connectedWithMetamask)
                  await model2.sendRequestToBuy(LandGall[index][0]);
                else
                  await model.sendRequestToBuy(LandGall[index][0]);
                showToast("Request sent",
                    context: context, backgroundColor: Colors.green);
              } catch (e) {
                print(e);
                showToast("Something Went Wrong",
                    context: context, backgroundColor: Colors.red);
              }
              SmartDialog.dismiss();
            }, () {
              List<String> allLatiLongi =
                  LandGall[index][4].toString().split('|');
              print(allLatiLongi);
              LandInfo landinfo = LandInfo(
                  LandGall[index][1].toString(),
                  LandGall[index][2].toString(),
                  LandGall[index][3].toString(),
                  LandGall[index][5].toString(),
                  LandGall[index][6].toString(),
                  LandGall[index][7].toString(),
                  LandGall[index][8],
                  LandGall[index][9].toString(),
                  LandGall[index][10]);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => viewLandDetails(
                            allLatitude: allLatiLongi[0],
                            allLongitude: allLatiLongi[1],
                            landinfo: landinfo,
                          )));
            });
          },
        ),
      ),
    );
  }

  Widget myLands() {
    if (isLoading) return CircularProgressIndicator();
    return Center(
      child: Container(
        width: isDesktop ? 900 : width,
        child: GridView.builder(
          padding: EdgeInsets.all(10),
          scrollDirection: Axis.vertical,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisExtent: 440,
              crossAxisCount: isDesktop ? 2 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20),
          itemCount: landInfo.length,
          itemBuilder: (context, index) {
            return landWid(
                landInfo[index][10],
                landInfo[index][1].toString(),
                landInfo[index][2].toString(),
                landInfo[index][3].toString(),
                landInfo[index][8],
                () => confirmDialog('Are you sure to make it on sell?', context,
                        () async {
                      SmartDialog.showLoading();
                      if (connectedWithMetamask)
                        await model2.makeForSell(landInfo[index][0]);
                      else
                        await model.makeForSell(landInfo[index][0]);
                      Navigator.pop(context);
                      await getLandInfo();
                      SmartDialog.dismiss();
                    }));
          },
        ),
      ),
    );
  }

  Widget addLand() {
    return Center(
      widthFactor: isDesktop ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            //color: Color(0xFFBb3b3cc),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all()),
        width: width,
        child: Form(
          key: _formKey,
          child: Column(
            // scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    area = val;
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'Area(SqFt)',
                    hintText: 'Enter Area in SqFt',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: CompositedTransformTarget(
                  link: this._layerLink,
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Land Address';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    controller: addressController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        autocomplete(value);
                        _overlayEntry.remove();
                        _overlayEntry = this._createOverlayEntry();
                        Overlay.of(context)!.insert(_overlayEntry);
                      } else {
                        if (predictions.length > 0 && mounted) {
                          setState(() {
                            predictions = [];
                          });
                        }
                      }
                    },
                    focusNode: this._focusNode,
                    //obscureText: true,
                    decoration: const InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(),
                      labelText: 'Address',
                      hintText: 'Enter Land Address',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Land Price';
                    }
                    return null;
                  },
                  //maxLength: 12,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  onChanged: (val) {
                    landPrice = val;
                  },
                  //obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'Land Price',
                    hintText: 'Enter Land Price',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter PID';
                    }
                    return null;
                  },
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  //maxLength: 10,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  onChanged: (val) {
                    propertyID = val;
                  },
                  //obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'PID',
                    hintText: 'Enter Property ID',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    surveyNo = val;
                  },
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  //obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'Survey No.',
                    hintText: 'Survey No.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: MaterialButton(
                  color: Colors.grey,
                  onPressed: () async {
                    allLatiLongi = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const landOnMap()));
                    if (allLatiLongi.isEmpty || allLatiLongi == "")
                      showToast("Please select area on map",
                          context: context, backgroundColor: Colors.red);
                    //print(res);
                  },
                  child: const Text('Draw Land on Map'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    MaterialButton(
                      color: Colors.grey,
                      onPressed: pickDocument,
                      child: const Text('Upload Document'),
                    ),
                    Text(docuName)
                  ],
                ),
              ),
              CustomButton(
                  'Add',
                  isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate() &&
                              allLatiLongi.isNotEmpty &&
                              allLatiLongi != "") {
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              SmartDialog.showLoading(
                                  msg: "Uploading Document");
                              bool isFileupload = await uploadDocument();
                              SmartDialog.dismiss();
                              if (isFileupload) {
                                if (connectedWithMetamask)
                                  await model2.addLand(
                                      area,
                                      addressController.text,
                                      allLatiLongi,
                                      landPrice,
                                      propertyID,
                                      surveyNo,
                                      docUrl);
                                else
                                  await model.addLand(
                                      area,
                                      addressController.text,
                                      allLatiLongi,
                                      landPrice,
                                      propertyID,
                                      surveyNo,
                                      docUrl);
                                showToast("Land Successfully Added",
                                    context: context,
                                    backgroundColor: Colors.green);
                                isFilePicked = false;
                              }
                            } catch (e) {
                              print(e);
                              showToast("Something Went Wrong",
                                  context: context,
                                  backgroundColor: Colors.red);
                            }

                            setState(() {
                              isLoading = false;
                            });
                          }

                          //model.makePaymentTestFun();
                        }),
              isLoading ? spinkitLoader : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget userProfile() {
    if (isLoading) return const CircularProgressIndicator();
    isUserVerified = userInfo[8];
    return Container(
      width: width,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          //color: Color(0xFFBb3b3cc),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          userInfo[8]
              ? Row(
                  children: const [
                    Text(
                      'Verified',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                    )
                  ],
                )
              : const Text(
                  'Not Yet Verified',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
          CustomTextFiled(userInfo[0].toString(), 'Wallet Address'),
          CustomTextFiled(userInfo[1].toString(), 'Name'),
          CustomTextFiled(userInfo[2].toString(), 'Age'),
          CustomTextFiled(userInfo[3].toString(), 'City'),
          CustomTextFiled(userInfo[4].toString(), 'Adhar Number'),
          CustomTextFiled(userInfo[5].toString(), 'Pan'),
          TextButton(
            onPressed: () {
              launchUrl(userInfo[6].toString());
            },
            child: const Text(
              '  View Document',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          CustomTextFiled(userInfo[7].toString(), 'Mail'),
        ],
      ),
    );
  }

  Widget drawer2() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black26, spreadRadius: 2)
        ],
        color: Color(0xFF272D34),
      ),
      width: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 20,
          ),
          const Icon(
            Icons.person,
            size: 50,
          ),
          const SizedBox(
            width: 30,
          ),
          Text(name,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 80,
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, counter) {
                return const Divider(
                  height: 2,
                );
              },
              itemCount: menuItems.length,
              itemBuilder: (BuildContext context, int index) {
                return MenuItemTile(
                  title: menuItems[index].title,
                  icon: menuItems[index].icon,
                  isSelected: screen == index,
                  onTap: () {
                    if (index == 6) {
                      Navigator.pop(context);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const home_page()));
                      Navigator.of(context).pushNamed(
                        '/',
                      );
                    }
                    if (index == 0) getProfileInfo();
                    if (index == 2) getLandInfo();
                    if (index == 3) getLandGallery();
                    if (index == 4) getMyReceivedRequest();
                    if (index == 5) getMySentRequest();
                    setState(() {
                      screen = index;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  _paymentDialog(buyerAdd, sellAdd, amountINR, total, ethval, reqID) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              backgroundColor: Colors.white,
              child: Container(
                margin: const EdgeInsets.all(10),
                height: 430.0,
                width: 320,
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'Confirm Payment',
                      style: TextStyle(fontSize: 30),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      buyerAdd.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Icon(
                      Icons.arrow_circle_down,
                      size: 30,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      sellAdd.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      "Total Amount in ₹",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      amountINR,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      '1 ETH = ' + ethval.toString() + '₹',
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      "Total ETH:",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      total.toString(),
                      style: const TextStyle(fontSize: 30),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton3('Cancel', () {
                          Navigator.of(context).pop();
                        }, Colors.white),
                        CustomButton3('Confirm', () async {
                          SmartDialog.showLoading();
                          try {
                            if (connectedWithMetamask)
                              await model2.makePayment(reqID, total);
                            else
                              await model.makePayment(reqID, total);
                            await getMySentRequest();
                            showToast("Payment Success",
                                context: context,
                                backgroundColor: Colors.green);
                          } catch (e) {
                            print(e);
                            showToast("Something Went Wrong",
                                context: context, backgroundColor: Colors.red);
                          }
                          SmartDialog.dismiss();
                          Navigator.of(context).pop();
                        }, Colors.blue)
                      ],
                    )
                  ],
                ),
              ));
        });
  }
}
