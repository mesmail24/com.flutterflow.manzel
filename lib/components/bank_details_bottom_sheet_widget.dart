import '../backend/api_requests/api_calls.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class BankDetailsBottomSheetWidget extends StatefulWidget {
  const BankDetailsBottomSheetWidget({
    Key key,
    this.bankId,
    this.bankJSON,
  }) : super(key: key);

  final int bankId;
  final dynamic bankJSON;

  @override
  _BankDetailsBottomSheetWidgetState createState() =>
      _BankDetailsBottomSheetWidgetState();
}

class _BankDetailsBottomSheetWidgetState
    extends State<BankDetailsBottomSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiCallResponse>(
      future: BankDetailsCall.call(
        bankId: widget.bankId,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: SpinKitRipple(
                color: Color(0xFF2971FB),
                size: 50,
              ),
            ),
          );
        }
        final columnBankDetailsResponse = snapshot.data;
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 68.5,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x80000000),
                    offset: Offset(0, 1),
                  )
                ],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.04, 22, 0, 0),
                    child: Container(
                      width: 24.06,
                      height: 23.76,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.2,
                        maxHeight: double.infinity,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: InkWell(
                        onTap: () async {
                          logFirebaseEvent(
                              'BANK_DETAILS_BOTTOM_SHEET_Icon_b8d7zqap_');
                          logFirebaseEvent('Icon_Bottom-Sheet');
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.clear,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 22, 75, 0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'qb244g7f' /* Bank Details */,
                            ),
                            style:
                                FlutterFlowTheme.of(context).bodyText1.override(
                                      fontFamily: 'Sofia Pro By Khuzaimah',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      useGoogleFonts: false,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20, 12, 0, 0),
              child: Container(
                width: 130,
                height: 93,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    getJsonField(
                      widget.bankJSON,
                      r'''$.bank_logo..alternativeText''',
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
                      child: Html(
                        data: getJsonField(
                          widget.bankJSON,
                          r'''$.bank_description''',
                        ).toString(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(20, 17, 20, 0),
                      child: Html(
                        data: getJsonField(
                          widget.bankJSON,
                          r'''$.bank_rules''',
                        ).toString(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.5, 69, 20.5, 30.57),
              child: FFButtonWidget(
                onPressed: () async {
                  logFirebaseEvent('BANK_DETAILS_BOTTOM_SHEET_CLOSE_BTN_ON_T');
                  logFirebaseEvent('Button_Bottom-Sheet');
                  Navigator.pop(context);
                },
                text: FFLocalizations.of(context).getText(
                  'ua6uqn3o' /* Close */,
                ),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 45,
                  color: FlutterFlowTheme.of(context).primaryColor,
                  textStyle: FlutterFlowTheme.of(context).subtitle2.override(
                        fontFamily: 'Sofia Pro By Khuzaimah',
                        color: Colors.white,
                        useGoogleFonts: false,
                      ),
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}