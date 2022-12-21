import 'package:manzel/common_alert_dialog/common_alert_dialog.dart';
import 'package:manzel/flutter_flow/custom_functions.dart';
import 'package:manzel/multi_video_player/feed_player/multi_manager/flick_multi_manager.dart';
import 'package:manzel/multi_video_player/feed_player/multi_manager/flick_multi_player.dart';
import 'package:video_player/video_player.dart';
import '../auth/auth_util.dart';
import '../auth/firebase_user_provider.dart';
import '../backend/api_requests/api_calls.dart';
import '../backend/backend.dart';
import 'package:manzel/common_widgets/manzel_icons.dart';
import '../components/no_result_widget.dart';
import 'package:manzel/app_state.dart' as globalVar;
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_video_player.dart';
import '../flutter_flow/custom_functions.dart' as functions;
import 'dart:async';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:app_settings/app_settings.dart';

import '../flutter_flow/flutter_flow_widgets.dart';

class HomeScreenWidget extends StatefulWidget {
  const HomeScreenWidget({
    Key? key,
    this.city,
    this.type,
    this.installmentRange,
    this.furnishing,
  }) : super(key: key);

  final String? city;
  final String? type;
  final double? installmentRange;
  final String? furnishing;

  @override
  _HomeScreenWidgetState createState() => _HomeScreenWidgetState();
}

class _HomeScreenWidgetState extends State<HomeScreenWidget> {
  Completer<ApiCallResponse>? _apiRequestCompleter;
  PageController? pageViewController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentItem = 0;
  var tapped_index;
  Map<String, bool> favourites = {};
  ValueNotifier<bool> bookMarkTapped = ValueNotifier<bool>(false);
  bool isPaused = false;
  bool? autoplayVal;
  List<VideoPlayerController> homeScreenPlayers = [];
  ValueNotifier<bool> isMuted = ValueNotifier<bool>(true);

  //ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  //FlickMultiManager flickMultiManager;
  Set<VideoPlayerController>? videoControllerSet;
  ApiCallResponse? apiData;

  VideoPlayerController? _currentController;
  int currentPropertyindex = 0;
  String? res;
  Map<String, VideoPlayerController> videocontrollerMap = {};
  ScrollController controller = ScrollController();

  static const _pageSize = 6;

  // final PagingController<int, dynamic> _pagingController =
  //     PagingController(firstPageKey: 0);

  bool? isInternetAvailable;

  late FlickMultiManager flickMultiManager;
  List propertyListData=[];
  int pageNumber=1;
  bool isNewPageFetched=false;
  bool isLastPage=false;


  @override
  void initState() {
    super.initState();
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('view_item_list');
      logFirebaseEvent('HOME_SCREEN_PAGE_HomeScreen_ON_PAGE_LOAD');
      logFirebaseEvent('HomeScreen_Set-App-Language');
      setAppLanguage(context, await FFAppState().locale);
      Future.delayed(const Duration(milliseconds: 500), () {
        setAppLanguage(context, FFAppState().locale);
      });
    });
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'HomeScreen'});
  //  _fetchPage(pageNumber);
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchPage(pageNumber);
      getBookMarks();

    });

    // _pagingController.addPageRequestListener((pageKey) {
    //   Future.delayed(const Duration(milliseconds: 500), () {
    //     _fetchPage(pageKey);
    //   });
    // });
    checkInternetStatus();
    flickMultiManager = FlickMultiManager();
    controller.addListener(_scrollListener);
  }

  void _scrollListener() {

    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if(!isLastPage){
        setState(() {
          isNewPageFetched = true;
        });
        print("at the end of list");
        _fetchPage(pageNumber++);

      }

    }
  }

  Future<void> getBookMarks() async {
    isInternetAvailable = await isInternetConnected();
    if (loggedIn&&(isInternetAvailable??false)) {
      callBookmarkListApi();
    }
  }

  Future<void> checkInternetStatus() async {
    isInternetAvailable = await isInternetConnected();
  }

  watchRouteChange() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !GoRouter.of(context).location.contains("fav")) {
        // Here you check for some changes in your route that indicate you are no longer on the page you have pushed before
        // do something
        favourites = FavouriteList.instance.favourite;
        // if (mounted) {
        //   setState(() {});
        // }
        GoRouter.of(context)
            .removeListener(watchRouteChange); // remove listener
      }
    });
  }

  Future<void> callBookmarkListApi() async {
    final result = await BookmarkListCall.call(
      userId: currentUserUid,
      authorazationToken: await FFAppState().authToken,
      version: await FFAppState().apiVersion,
    );
    print("REsult>>>>>>>>>>>>>${result.jsonBody}");
    List<dynamic> favList = await result.jsonBody['result'];
    favList.forEach((element) {
      favourites[element] = true;
    });
    FavouriteList.instance.setFavourite(favourites);
     if (mounted) setState(() {});
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      bool isInternetAvailable = await isInternetConnected();
      if (isInternetAvailable) {
        // if (loggedIn) {
        //    callBookmarkListApi();
        // }
        final apiResponse = await PropertiesCall.call(
          pageNumber: pageKey.toString(),
          pageSize: _pageSize.toString(),
          locale: FFAppState().locale,
        );
        apiData = apiResponse;
        final listData = getJsonField(
              (apiResponse.jsonBody ?? ''),
              r'''$.data''',
            )?.toList() ??
            [];
          isNewPageFetched = false;
        isLastPage = listData.length < _pageSize;
        if (isLastPage) {
          propertyListData.addAll(listData);
          setState((){});
         // _pagingController.appendLastPage(newItems);
        } else {
          // 3.1 Use this for offset based pagination
          // final nextPageKey = pageKey + newItems.length;
          // 3.2 Use this for page based pagination
          propertyListData.addAll(listData);
          setState((){});
        //  _pagingController.appendPage(newItems, nextPageKey);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => CommonAlertDialog(
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (error) {
      //_pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color(0x3F000000),
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        )
                      ],
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Image.asset(
                        'assets/images/home_bg.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0, -0.7),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/manzel_logo_white.png',
                            width: 43,
                            height: 31,
                            fit: BoxFit.fitHeight,
                          ),
                          if (loggedIn)
                            StreamBuilder<List<NotificationsRecord>>(
                              stream: queryNotificationsRecord(
                                queryBuilder: (notificationsRecord) =>
                                    notificationsRecord
                                        .where('user_id',
                                            isEqualTo: currentUserReference)
                                        .where('is_read', isEqualTo: 0),
                              ),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Container(
                                    child: Icon(
                                      Manzel.notification,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  );
                                }
                                List<NotificationsRecord>
                                    notificationsBadgeNotificationsRecordList =
                                    snapshot.data!;
                                return InkWell(
                                  onTap: () async {
                                    flickMultiManager.pause();
                                    logFirebaseEvent(
                                        'HOME_SCREEN_notificationsBadge_ON_TAP');
                                    logFirebaseEvent(
                                        'notificationsBadge_Navigate-To');
                                    context.pushNamed('Notifications');
                                  },
                                  child: Badge(
                                    badgeContent: Text(
                                      valueOrDefault<String>(
                                        functions.notificationBadgeCount(
                                            notificationsBadgeNotificationsRecordList
                                                .toList()),
                                        '0',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyText1
                                          .override(
                                            fontFamily: 'AvenirArabic',
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                    showBadge: functions.notificationBadgeCount(
                                            notificationsBadgeNotificationsRecordList
                                                .toList()) !=
                                        '0',
                                    shape: BadgeShape.circle,
                                    badgeColor: FlutterFlowTheme.of(context)
                                        .secondaryRed,
                                    elevation: 4,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        7, 7, 7, 7),
                                    position: BadgePosition.topEnd(),
                                    animationType: BadgeAnimationType.scale,
                                    toAnimate: true,
                                    child: Icon(
                                      Manzel.notification,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0, 0.75),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(14, 0, 14, 0),
                      child: InkWell(
                        onTap: () async {
                          flickMultiManager.pause();
                          logFirebaseEvent(
                              'HOME_SCREEN_PAGE_Text_iowqhltc_ON_TAP');
                          logFirebaseEvent('Text_Navigate-To');
                          context.pushNamed(
                            'WhereAreYouLooking',
                            queryParams: {
                              'homeScreenLength': serializeParam(
                                  videoPlayers.length, ParamType.int),
                            }.withoutNulls,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType:
                                    PageTransitionType.bottomToTop,
                              ),
                            },
                          );
                          GoRouter.of(context).addListener(() {
                            watchRouteChange();
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 5,
                                color: Color(0x41000000),
                                offset: Offset(0, 3),
                              )
                            ],
                            borderRadius: BorderRadius.circular(8),
                            shape: BoxShape.rectangle,
                          ),
                          alignment: AlignmentDirectional(0, 0),
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(23, 0, 12, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'qnr0o42y' /* Where are you looking? */,
                                  ),
                                  textAlign: TextAlign.start,
                                  style:
                                      FlutterFlowTheme.of(context).bodyText1,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        logFirebaseEvent('search');
                                        await showDialog(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'HomeScreenAlertTitle',
                                                ),
                                              ),
                                              content: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'HomeScreenAlertMessage',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext),
                                                  child: Text(
                                                      FFAppState().locale ==
                                                              'en'
                                                          ? 'Ok'
                                                          : 'موافق'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0, 0, 10, 0),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Color(0xFFF4F4F4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.map_outlined,
                                            color: Colors.black,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        flickMultiManager.pause();
                                        logFirebaseEvent('search');
                                        logFirebaseEvent(
                                            'HOME_SCREEN_Container_13mjruev_ON_TAP');
                                        logFirebaseEvent(
                                            'Container_Navigate-To');
                                        context.pushNamed(
                                          'Filter',
                                          queryParams: {
                                            'homeScreenLength':
                                                serializeParam(
                                                    videoPlayers.length,
                                                    ParamType.int),
                                          }.withoutNulls,
                                          extra: <String, dynamic>{
                                            kTransitionInfoKey:
                                                TransitionInfo(
                                              hasTransition: true,
                                              transitionType:
                                                  PageTransitionType
                                                      .bottomToTop,
                                            ),
                                          },
                                        );
                                        GoRouter.of(context).addListener(() {
                                          watchRouteChange();
                                        });
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Color(0xFFF4F4F4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Manzel.filter,
                                          color: Colors.black,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                separatorBuilder: (context, int) => Container(
                  height: 50,
                ),
                itemCount: propertyListData.length,
                itemBuilder: (context, index) {
                  propertyListData[index]['isBookmarked'] =
                      favourites[propertyListData[index]['id'].toString()] ?? false;
                  return Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                    child: InkWell(
                      onTap: () async {
                        flickMultiManager.pause();
                        logFirebaseEvent('view_item');
                        logFirebaseEvent(
                            'HOME_SCREEN_PAGE_propertyCard_ON_TAP');
                        // propertyDetails
                        logFirebaseEvent('propertyCard_propertyDetails');
                        context.pushNamed(
                          'PropertyDetails',
                          queryParams: {
                            'propertyId': serializeParam(
                                getJsonField(
                                  propertyListData[index],
                                  r'''$.id''',
                                ),
                                ParamType.int),
                            'jsonData': serializeParam(
                                propertyListData[index], ParamType.JSON),
                            'path': serializeParam(
                                getJsonField(
                                  propertyListData[index],
                                  r'''$.attributes.video_manifest_uri''',
                                ),
                                ParamType.String),
                          }.withoutNulls,
                        );
                        GoRouter.of(context).addListener(() {
                          watchRouteChange();
                        });
                        //         }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Stack(
                              children: [
                                if (functions
                                    .videoPlayerVisibilty(getJsonField(
                                  propertyListData[index],
                                  r'''$.attributes.video_manifest_uri''',
                                )))
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.95,
                                      height:
                                      MediaQuery.of(context).size.height *
                                          0.4,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child:
                                      FlickMultiPlayer(
                                        url: getJsonField(
                                          propertyListData[index],
                                          r'''$.attributes.video_manifest_uri''',
                                        ),
                                        flickMultiManager: flickMultiManager,//flickMultiManager,
                                        image: getJsonField(
                                          propertyListData[index],
                                          r'''$.attributes.video_poster_image''',
                                        ),
                                      ),
                                      //),
                                    ),
                                  ),


                                if (!functions
                                    .videoPlayerVisibilty(getJsonField(
                                  propertyListData[index],
                                  r'''$.attributes.video_manifest_uri''',
                                )))
                                  Builder(
                                    builder: (context) {
                                      final propertyImages = getJsonField(
                                        propertyListData[index],
                                        r'''$..property_images.data''',
                                      ).toList();

                                      return Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        height: MediaQuery.of(context)
                                            .size
                                            .height *
                                            0.3,
                                        child: Stack(
                                          children: [
                                            PageView.builder(
                                              controller:
                                              pageViewController ??=
                                                  PageController(
                                                      initialPage: min(
                                                          0,
                                                          propertyImages
                                                              .length -
                                                              1)),
                                              scrollDirection:
                                              Axis.horizontal,
                                              itemCount:
                                              propertyImages.length,
                                              itemBuilder: (context,
                                                  propertyImagesIndex) {
                                                final propertyImagesItem =
                                                propertyImages[
                                                propertyImagesIndex];
                                                return Visibility(
                                                  visible: !functions
                                                      .videoPlayerVisibilty(
                                                      getJsonField(
                                                        propertyImagesItem,
                                                        r'''$.attributes.video_manifest_uri''',
                                                      )),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                                    child: CachedNetworkImage(
                                                      imageUrl: getJsonField(
                                                        propertyImagesItem,
                                                        r'''$.attributes.formats.medium.url''',
                                                      ),
                                                      width: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .width,
                                                      height: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .height *
                                                          0.3,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0, 0.7),
                                              child: SmoothPageIndicator(
                                                controller:
                                                pageViewController ??=
                                                    PageController(
                                                        initialPage: min(
                                                            0,
                                                            propertyImages
                                                                .length -
                                                                1)),
                                                count: propertyImages.length,
                                                axisDirection:
                                                Axis.horizontal,
                                                onDotClicked: (i) {
                                                  pageViewController!
                                                      .animateToPage(
                                                    i,
                                                    duration: Duration(
                                                        milliseconds: 500),
                                                    curve: Curves.ease,
                                                  );
                                                },
                                                effect: SlideEffect(
                                                  spacing: 8,
                                                  radius: 3,
                                                  dotWidth: 6,
                                                  dotHeight: 6,
                                                  dotColor: Color(0x80FFFFFF),
                                                  activeDotColor:
                                                  Colors.white,
                                                  paintStyle:
                                                  PaintingStyle.fill,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),



                                ///************************ bookmark icon button on video player*******************************
                                Align(
                                  alignment: AlignmentDirectional(1, -0.95),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 12, 15, 0),
                                    child: ValueListenableBuilder<bool>(
                                      builder: (BuildContext context, value,
                                          Widget? child) {
                                        return (bookMarkTapped.value &&
                                            propertyListData[index] ==
                                                tapped_index)
                                            ? SizedBox(
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                // color: propertiesItem[
                                                // "isBookmarked"]
                                                //     ? Color(0x4DFF0000)
                                                //     : Color(0x4D000000),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Manzel.favourite,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ))
                                            : InkWell(
                                            onTap: () async {
                                              propertyListData[index]['isBookmarked'] =
                                              propertyListData[index]['isBookmarked']
                                                  ? true
                                                  : false;
                                              tapped_index = index;
                                              bookMarkTapped.value = true;

                                              logFirebaseEvent(
                                                  'add_to_wishlist');
                                              logFirebaseEvent(
                                                  'HOME_SCREEN_Container_jprwonvd_ON_TAP');
                                              if (loggedIn) {
                                                if (propertyListData[index]['isBookmarked']) {
                                                  logFirebaseEvent(
                                                      'Container_Backend-Call');
                                                  isInternetAvailable =
                                                  await isInternetConnected();
                                                  if (isInternetAvailable ??
                                                      false) {
                                                    final bookmarkApiResponse =
                                                    await BookmarkPropertyCall
                                                        .call(
                                                      userId:
                                                      currentUserUid,
                                                      authorazationToken:
                                                      FFAppState()
                                                          .authToken,
                                                      propertyId:
                                                      valueOrDefault<
                                                          String>(
                                                        getJsonField(
                                                          propertyListData[index],
                                                          r'''$.id''',
                                                        ).toString(),
                                                        '0',
                                                      ),
                                                      version:
                                                      FFAppState()
                                                          .apiVersion,
                                                    );
                                                    if ((bookmarkApiResponse
                                                        .statusCode) ==
                                                        200) {
                                                      favourites.remove(
                                                          propertyListData[index][
                                                          "id"]
                                                              .toString());
                                                      propertyListData[index][
                                                      "isBookmarked"] =
                                                      false;
                                                      bookMarkTapped
                                                          .value = false;
                                                    }
                                                    else if((bookmarkApiResponse
                                                        .statusCode) ==
                                                        403){
                                                      unAuthorizedUser(context, mounted);
                                                    }
                                                    else {
                                                      logFirebaseEvent(
                                                          'Icon_Show-Snack-Bar');
                                                      ScaffoldMessenger
                                                          .of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            functions.snackBarMessage(
                                                                'error',
                                                                FFAppState()
                                                                    .locale),
                                                            style:
                                                            TextStyle(
                                                              color: FlutterFlowTheme.of(
                                                                  context)
                                                                  .white,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              fontSize:
                                                              16,
                                                              height: 2,
                                                            ),
                                                          ),
                                                          duration: Duration(
                                                              milliseconds:
                                                              4000),
                                                          backgroundColor:
                                                          FlutterFlowTheme.of(
                                                              context)
                                                              .primaryRed,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                      context) =>
                                                          CommonAlertDialog(
                                                            onCancel: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                    );
                                                  }
                                                } else {
                                                  logFirebaseEvent(
                                                      'Container_Backend-Call');
                                                  if (isInternetAvailable ??
                                                      false) {
                                                    final bookmarkApiResponse =
                                                    await BookmarkPropertyCall
                                                        .call(
                                                      userId:
                                                      currentUserUid,
                                                      authorazationToken:
                                                      FFAppState()
                                                          .authToken,
                                                      propertyId:
                                                      valueOrDefault<
                                                          String>(
                                                        getJsonField(
                                                          propertyListData[index],
                                                          r'''$.id''',
                                                        ).toString(),
                                                        '0',
                                                      ),
                                                      version:
                                                      FFAppState()
                                                          .apiVersion,
                                                    );
                                                    if ((bookmarkApiResponse
                                                        .statusCode) ==
                                                        200) {
                                                      favourites[
                                                        propertyListData[index]['id'].toString()] =
                                                      true;
                                                      propertyListData[index][
                                                      "isBookmarked"] =
                                                      true;
                                                      bookMarkTapped
                                                          .value = false;
                                                    }  else if((bookmarkApiResponse
                                                        .statusCode) ==
                                                        403){
                                                      unAuthorizedUser(context, mounted);
                                                    }
                                                    else {
                                                      logFirebaseEvent(
                                                          'Icon_Show-Snack-Bar');
                                                      ScaffoldMessenger
                                                          .of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            functions.snackBarMessage(
                                                                'error',
                                                                FFAppState()
                                                                    .locale),
                                                            style:
                                                            TextStyle(
                                                              color: FlutterFlowTheme.of(
                                                                  context)
                                                                  .white,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              fontSize:
                                                              16,
                                                              height: 2,
                                                            ),
                                                          ),
                                                          duration: Duration(
                                                              milliseconds:
                                                              4000),
                                                          backgroundColor:
                                                          FlutterFlowTheme.of(
                                                              context)
                                                              .primaryRed,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                      context) =>
                                                          CommonAlertDialog(
                                                            onCancel: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                    );
                                                  }
                                                }
                                              } else {
                                                // videoPlayers[
                                                // propertiesIndex]
                                                //     .pause();
                                                // logFirebaseEvent(
                                                //     'Container_Navigate-To');
                                                context
                                                    .pushNamed('Login');
                                              }
                                            },
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color:  propertyListData[index][
                                                "isBookmarked"]
                                                    ? Color(0x4DFF0000)
                                                    : Color(0x4D000000),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Manzel.favourite,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ));
                                      },
                                      valueListenable: bookMarkTapped,
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment: AlignmentDirectional(-0.9, 1),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 18, 18),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Color(0x80F3F1F1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color(0x80F3F1F1),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(30),
                                        child: Image.network(
                                          getJsonField(
                                            propertyListData[index],
                                            r'''$.attributes.managed_by.data.attributes.company_logo.data.attributes.url''',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (functions.conditionalVisibility(
                                    getJsonField(
                                      propertyListData[index],
                                      r'''$.attributes.property_status''',
                                    ).toString(),
                                    'Booked'))
                                  Align(
                                    alignment:
                                    AlignmentDirectional(-0.9, -0.89),
                                    child: Container(
                                      width: 80,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFD7D7D7),
                                        borderRadius:
                                        BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsetsDirectional
                                                .fromSTEB(10, 1, 10, 1),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'qtso45vv' /* Booked */,
                                              ),
                                              style:
                                              FlutterFlowTheme.of(context)
                                                  .bodyText1
                                                  .override(
                                                fontFamily:
                                                'AvenirArabic',
                                                color: FlutterFlowTheme
                                                    .of(context)
                                                    .white,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w500,
                                                useGoogleFonts: false,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (functions.conditionalVisibility(
                                    getJsonField(
                                      propertyListData[index],
                                      r'''$.attributes.property_status''',
                                    ).toString(),
                                    'Soon'))
                                  Align(
                                    alignment:
                                    AlignmentDirectional(-0.9, -0.89),
                                    child: Container(
                                      width: 80,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryColor,
                                        borderRadius:
                                        BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsetsDirectional
                                                .fromSTEB(10, 1, 10, 1),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'juw40663' /* Coming soon */,
                                              ),
                                              style:
                                              FlutterFlowTheme.of(context)
                                                  .bodyText1
                                                  .override(
                                                fontFamily:
                                                'AvenirArabic',
                                                color: FlutterFlowTheme
                                                    .of(context)
                                                    .white,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w500,
                                                useGoogleFonts: false,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            EdgeInsetsDirectional.fromSTEB(4, 14, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  getJsonField(
                                    propertyListData[index],
                                    r'''$.attributes.property_name''',
                                  ).toString(),
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyText1
                                      .override(
                                    fontFamily: 'AvenirArabic',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'etpebw43' /* Approved Banks */,
                                  ),
                                  textAlign: TextAlign.end,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyText1
                                      .override(
                                    fontFamily: 'AvenirArabic',
                                    color: Color(0xFF474747),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            EdgeInsetsDirectional.fromSTEB(4, 1, 0, 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Manzel.location_pin,
                                      color: Color(0xFF130F26),
                                      size: 11,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          4, 0, 0, 0),
                                      child: Text(
                                        getJsonField(
                                          propertyListData[index],
                                          r'''$..attributes.city.data.attributes.city_name''',
                                        ).toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyText1
                                            .override(
                                          fontFamily: 'AvenirArabic',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
                                          useGoogleFonts: false,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          3, 0, 3, 0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'efcxmcgl' /* ,  */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyText1
                                            .override(
                                          fontFamily: 'AvenirArabic',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
                                          useGoogleFonts: false,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      getJsonField(
                                        propertyListData[index],
                                        r'''$..property_district''',
                                      ).toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyText1
                                          .override(
                                        fontFamily: 'AvenirArabic',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w300,
                                        useGoogleFonts: false,
                                      ),
                                    ),
                                  ],
                                ),
                                // Generated code for this Row Widget...
                                Builder(
                                  builder: (context) {
                                    final banks = getJsonField(
                                      propertyListData[index],
                                      r'''$.attributes.banks.data''',
                                    ).toList();
                                    return Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: List.generate(banks.length,
                                              (banksIndex) {
                                            final banksItem = banks[banksIndex];
                                            return Padding(
                                              padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0, 0, 2, 0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Color(0xFF8C8C8C),
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(11),
                                                  child: Image.network(
                                                    getJsonField(
                                                      banksItem,
                                                      r'''$.attributes.bank_logo.data.attributes.url''',
                                                    ),
                                                    width: 22,
                                                    height: 22,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            EdgeInsetsDirectional.fromSTEB(4, 0, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '998is2ya' /* Installment starting from */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .title3
                                      .override(
                                    fontFamily: 'Sofia Pro By Khuzaimah',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'gqe4w739' /* Total property price */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyText2
                                      .override(
                                    fontFamily: 'AvenirArabic',
                                    color: Color(0xFF474747),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            EdgeInsetsDirectional.fromSTEB(4, 1, 0, 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      valueOrDefault<String>(
                                        functions.formatAmount(getJsonField(
                                          propertyListData[index],
                                          r'''$.attributes.property_initial_installment''',
                                        ).toString()),
                                        '0',
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyText1
                                          .override(
                                        fontFamily:
                                        'Sofia Pro By Khuzaimah',
                                        color:
                                        FlutterFlowTheme.of(context)
                                            .primaryColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        useGoogleFonts: false,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5, 10, 0, 0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'l38if619' /*  SAR/Monthly */,
                                        ),
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyText1
                                            .override(
                                          fontFamily: 'AvenirArabic',
                                          color:
                                          FlutterFlowTheme.of(context)
                                              .primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          useGoogleFonts: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0, 0, 3, 0),
                                      child: Text(
                                        valueOrDefault<String>(
                                          functions
                                              .formatAmountWithoutDecimal(
                                              valueOrDefault<String>(
                                                getJsonField(
                                                  propertyListData[index],
                                                  r'''$..property_price''',
                                                ).toString(),
                                                '0',
                                              )),
                                          '0',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyText2
                                            .override(
                                          fontFamily: 'AvenirArabic',
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          useGoogleFonts: false,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'dhoik8q5' /*  SAR */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyText2
                                          .override(
                                        fontFamily: 'AvenirArabic',
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        useGoogleFonts: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            color: Color(0xFFECECEC),
                          ),
                        ],
                      ),
                    ),
                    //),
                    //  },

                    // );
                    //  },
                  );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          height: 400,
                          margin: EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child:
                            FlickMultiPlayer(
                              url: propertyListData[index]['attributes']['video_manifest_uri'],
                              flickMultiManager: flickMultiManager,
                              image:  '',
                            ),
                          )),
                      Text('Testing Video Playes', style: TextStyle(fontSize: 20),)
                    ],
                  );
                },
              ),
            ),
            if(isNewPageFetched)
            CircularProgressIndicator()
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future waitForApiRequestCompleter({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = _apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}













