import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../../utils/util.dart';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    p('$blueDot The DataDriver About is building ...');
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Check the sizing information here and return your UI
        if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
          return const Center(
            child: AboutCard(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              padding: 24.0,
              elevation: 4.0,
            ),
          );
        }

        if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
          return const Center(
            child: AboutCard(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              padding: 16.0,
              elevation: 6.0,
            ),
          );
        }

        if (sizingInformation.deviceScreenType == DeviceScreenType.mobile) {
          return const Center(
            child: AboutCard(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              padding: 12.0,
              elevation: 16.0,
            ),
          );
        }

        return Container(color: Colors.purple);
      },
    );
  }
}

class AboutCard extends StatelessWidget {
  const AboutCard(
      {Key? key, required this.fontSize, required this.fontWeight, required this.padding, required this.elevation})
      : super(key: key);

  final double fontSize;
  final FontWeight fontWeight;
  final double padding;
  final double elevation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About DataDriver+'),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Card(
          elevation: elevation,
          child: Column(
            children: [
              Image.asset('assets/images/m2.jpg', fit: BoxFit.fill),
              const SizedBox(
                height: 20,
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    'The DataDriver suite comprises of a cloud based '
                    'streaming data backend and a Flutter app '
                    'to drive the data generation and to observe results',
                    style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
