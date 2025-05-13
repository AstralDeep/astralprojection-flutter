import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String message;
  final String size;

  const LoadingSpinner({
    Key? key,
    this.message = 'Loading...',
    this.size = 'md',
  }) : super(key: key);

  double getSpinnerSize() {
    switch (size) {
      case 'sm':
        return 16.0;
      case 'lg':
        return 48.0;
      case 'md':
      default:
        return 32.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: getSpinnerSize(),
          height: getSpinnerSize(),
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            backgroundColor: Colors.black12,
          ),
        ),
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              message,
              style: TextStyle(
                fontSize: size == 'sm' ? 13.0 : 16.0,
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
