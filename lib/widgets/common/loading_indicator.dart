import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.overlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              message!,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(child: loadingWidget),
      );
    }

    return Center(child: loadingWidget);
  }
}