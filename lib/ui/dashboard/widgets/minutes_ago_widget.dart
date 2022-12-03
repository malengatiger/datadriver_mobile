import 'package:flutter/material.dart';

import '../../../utils/providers.dart';

class MinutesAgoWidget extends StatelessWidget {
  const MinutesAgoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Data from ', style: TextStyle(fontSize: 12),),
        const SizedBox(width: 8,),
        Text('$minutesAgo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),),
        const SizedBox(width: 8,),
        const Text('minutes before', style: TextStyle(fontSize: 12),),
        const SizedBox(width: 4,),
        Text('${DateTime.now().hour}:${DateTime.now().minute}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
      ],
    );
  }
}
