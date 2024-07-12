import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../global/provider_implementation/country_provider.dart';

class CountryDropdownWidget extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle? hintStyle;
  final String hintText;
  final String? Function(String?)? validator;

  const CountryDropdownWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.validator,
    required this.hintStyle,
  });

  @override
  State<CountryDropdownWidget> createState() => _CountryDropdownWidgetState();
}

class _CountryDropdownWidgetState extends State<CountryDropdownWidget> {
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final countryProvider = Provider.of<CountryProvider>(context);

    return countryProvider.isLoading
        ? const CircularProgressIndicator()
        : countryProvider.hasError
            ? const Text('Failed to load countries')
            : Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 60,
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: widget.hintStyle ?? GoogleFonts.aBeeZee(),
                      fillColor: Colors.white,
                      errorStyle: const TextStyle(color: Colors.red),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 88, 83, 83)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    value: _selectedCountry,
                    items: countryProvider.countries.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCountry = newValue;
                      });
                      widget.controller.text = newValue!;
                    },
                    validator: widget.validator,
                  ),
                ),
              );
  }
}
