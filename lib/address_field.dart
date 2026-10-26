import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'geocode.dart';
import 'theme.dart';

// address box w/ suggestions
class AddressField extends StatefulWidget {
  final TextEditingController? controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool autofocus;
  final void Function(LatLng point, String name) onPicked;
  final void Function(String text) onSubmitted;

  const AddressField({
    super.key,
    this.controller,
    required this.decoration,
    this.style,
    this.autofocus = false,
    required this.onPicked,
    required this.onSubmitted,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  late final _controller = widget.controller ?? TextEditingController();
  final _focus = FocusNode();
  int _latest = 0;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // debounce so every keystroke isnt a request
  Future<Iterable<(LatLng, String)>> _suggest(TextEditingValue value) async {
    final text = value.text.trim();
    if (text.length < 3) return [];
    final id = ++_latest;
    await Future.delayed(Duration(milliseconds: 350));
    if (id != _latest) return [];
    try {
      return await suggestAddresses(text);
    } catch (_) {
      return []; // offline
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => RawAutocomplete<(LatLng, String)>(
          textEditingController: _controller,
          focusNode: _focus,
          optionsBuilder: _suggest,
          displayStringForOption: (option) => option.$2,
          onSelected: (option) {
            _focus.unfocus();
            widget.onPicked(option.$1, option.$2);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            style: widget.style,
            decoration: widget.decoration,
            onSubmitted: widget.onSubmitted,
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 6),
              child: Material(
                color: GG.surface,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: GG.corner,
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 280, maxWidth: constraints.maxWidth),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(indent: 16),
                    itemBuilder: (context, i) {
                      final option = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        minTileHeight: 48,
                        title: Text(option.$2, style: TextStyle(fontSize: 14, color: GG.text)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
