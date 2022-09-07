import 'package:flutter/material.dart';

// custom radio widget for filtering searches
class MyRadioListTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String leading;
  final ValueChanged<T?> onChanged;

  // ignore: use_key_in_widget_constructors
  const MyRadioListTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        onChanged(value);
      },
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          children: [
            _customRadioButton,
          ],
        ),
      ),
    );
  }

  Widget get _customRadioButton {
    final bool isSelected = value == groupValue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.grey,
          // width: 2,
        ),
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  blurRadius: 3,
                  color: Colors.white,
                )
              ]
            : null,
      ),
      child: Text(
        leading,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
