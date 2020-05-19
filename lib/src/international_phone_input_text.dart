//library international_phone_input;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:international_phone_input/src/phone_service.dart';

import 'country.dart';

class InternationalPhoneInputs extends StatefulWidget {
  final void Function(String phoneNumber, String internationalizedPhoneNumber,
      String isoCode) onPhoneNumberChange;
  final String initialPhoneNumber;
  final phoneTextController;

  final String initialSelection;
  final String errorText;
  final String dbNumber;
  final Color dialColor;
  final TextStyle inputStyle;
  final String hintText;
  final String labelText;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final TextStyle labelStyle;
  final List<String> enabledCountries;
  final void Function(String phoneNumber, String internationalizedPhoneNumber,
      String isoCode) onValidPhoneNumber;
  final int errorMaxLines;
  final Color borderColor;
  final Widget suffixIcon;

  InternationalPhoneInputs({this.onPhoneNumberChange,
    this.dbNumber,
    this.phoneTextController,
    this.onValidPhoneNumber,
    this.inputStyle,
    this.dialColor,
    this.borderColor,
    this.suffixIcon,
    this.initialPhoneNumber,
    this.initialSelection,
    this.errorText,
    this.hintText,
    this.labelText,
    this.errorStyle,
    this.hintStyle,
    this.labelStyle,
    this.enabledCountries = const [],
    this.errorMaxLines});

  static Future<String> internationalizeNumber(String number, String iso) {
    return PhoneService.getNormalizedPhoneNumber(number, iso);
  }

  //get the phone number and the code
  Future <List<String>> splitPhoneNumber(context) async {
    List<Country> countries = await _InternationalPhoneInputState()._fetchCountryData(context);
    List <String> splitNumber = [];
    countries.forEach((c) {
      if (dbNumber.indexOf(c.dialCode) != -1) {
        String phone = dbNumber.replaceAll(c.dialCode, '');
        splitNumber.add(c.dialCode);
        splitNumber.add(phone);
      }
    });
    return splitNumber;
  }

  @override
  _InternationalPhoneInputState createState() =>
      _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInputs> {
  Country selectedItem;
  List<Country> itemList = [];

  String errorText;
  String hintText;
  String labelText;

  TextStyle errorStyle;
  TextStyle hintStyle;
  TextStyle labelStyle;

  int errorMaxLines;

  bool hasError = false;

  _InternationalPhoneInputState();

  var phoneTextController = TextEditingController();

  @override
  void initState() {
    print('object');
    errorText = widget.errorText ?? 'Please enter a valid phone number';
    hintText = widget.hintText ?? 'eg. 244056345';
    labelText = widget.labelText;
    errorStyle = widget.errorStyle;
    hintStyle = widget.hintStyle;
    labelStyle = widget.labelStyle;
    errorMaxLines = widget.errorMaxLines;

    phoneTextController.addListener(_validatePhoneNumber);
    phoneTextController.text = widget.initialPhoneNumber;

    _fetchCountryData(context).then((list) {
      Country preSelectedItem;

      if (widget.initialSelection != null) {
        preSelectedItem = list.firstWhere(
                (e) =>
            (e.code.toUpperCase() ==
                widget.initialSelection.toUpperCase()) ||
                (e.dialCode == widget.initialSelection.toString()),
            orElse: () => list[0]);
      } else {
        preSelectedItem = list[0];
      }

      setState(() {
        itemList = list;
        selectedItem = preSelectedItem;
      });
    });

    super.initState();
  }

  _validatePhoneNumber() {
    String phoneText = phoneTextController.text;
    if (phoneText != null && phoneText.isNotEmpty) {
      PhoneService.parsePhoneNumber(phoneText, selectedItem.code)
          .then((isValid) {
        setState(() {
          hasError = !isValid;
        });

        if (widget.onPhoneNumberChange != null) {
          if (isValid) {
            PhoneService.getNormalizedPhoneNumber(phoneText, selectedItem.code)
                .then((number) {
              widget.onPhoneNumberChange(phoneText, number, selectedItem.code);
            });
          } else {
            widget.onPhoneNumberChange('', '', selectedItem.code);
          }
        }
      });
    }
  }

  Future<List<Country>> _fetchCountryData(context) async {
    var list = await DefaultAssetBundle.of(context)
        .loadString('packages/international_phone_input/assets/countries.json');
    List<dynamic> jsonList = json.decode(list);
    List<Country> countries = List<Country>.generate(jsonList.length, (index) {
      Map<String, String> elem = Map<String, String>.from(jsonList[index]);
      if (widget.enabledCountries.isEmpty) {
        return Country(
            name: elem['en_short_name'],
            code: elem['alpha_2_code'],
            dialCode: elem['dial_code'],
            flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png');
      } else if (widget.enabledCountries.contains(elem['alpha_2_code']) ||
          widget.enabledCountries.contains(elem['dial_code'])) {
        return Country(
            name: elem['en_short_name'],
            code: elem['alpha_2_code'],
            dialCode: elem['dial_code'],
            flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png');
      } else {
        return null;
      }
    });

    countries.removeWhere((value) => value == null);

    return countries;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phoneTextController !=null)
      if(widget.phoneTextController.text!='')
        phoneTextController = widget.phoneTextController;
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 60,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                      //                    <--- top side
                      color: Colors.white,
                    ))),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 8, right: 5),
            margin: EdgeInsets.only(right: 10),
            height: 60,
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    //                    <--- top side
                    color: Colors.white,
                  ),
                )),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Country>(
                icon: Container(),
                isDense: true,
                value: selectedItem,
                onChanged: (Country newValue) {
                  setState(() {
                    selectedItem = newValue;
                  });
                  _validatePhoneNumber();
                },
                items: itemList.map<DropdownMenuItem<Country>>((Country value) {
                  return DropdownMenuItem<Country>(
                    value: value,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Image.asset(
                            value.flagUri,
                            width: 20.0,
                            package: 'international_phone_input',
                          ),
                          SizedBox(width: 4),
                          Text(
                            value.dialCode,
                            style: TextStyle(
                                color: widget.dialColor != null ? widget
                                    .dialColor : Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Flexible(
              child: TextFormField(
                style: widget.inputStyle != null
                    ? widget.inputStyle
                    : new TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                controller: phoneTextController,
                decoration: InputDecoration(
                    enabledBorder: new UnderlineInputBorder(
                        borderSide: new BorderSide(
                            color: widget.borderColor != null
                                ? widget.borderColor
                                : Colors.white)),
                    hintText: hintText,
                    labelText: labelText,
                    errorText: hasError ? errorText : null,
                    hintStyle: hintStyle ?? null,
                    labelStyle: labelStyle != null
                        ? labelStyle
                        : new TextStyle(color: Colors.white70),
                    errorMaxLines: errorMaxLines ?? 3,
                    suffixIcon: widget.suffixIcon != null
                        ? widget.suffixIcon
                        : new GestureDetector(
                      onTap: null,
                      child: new Icon(
                        Icons.phone,
                        color: Colors.white,
                      ),
                    )),
                validator: (phoneValue) {
                  if (phoneValue.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (hasError) return null;
                  if (widget.errorText != null)
                    return widget.errorText;
                  return null;
                },
              ))
        ],
      ),
    );
  }
}
