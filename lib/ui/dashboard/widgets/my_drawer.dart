import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key, required this.onSelected}) : super(key: key);
  final Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.brown[100],
      child: Column(
        children: [
          Card(
            elevation: 4,
              child: Image.asset('assets/images/m2.jpg', fit: BoxFit.fill,)),
          const SizedBox(height: 8,),
          const Text('Navigation'),
          const SizedBox(height: 20,),
          Expanded(child: ListView(
            children:  [
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  onSelected(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('City Aggregated Data'),
                onTap: () {
                  onSelected(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('City Maps'),
                onTap: () {
                  onSelected(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.generating_tokens),
                title: const Text('Data Generation'),
                onTap: () {
                  onSelected(3);
                },
              ),
            ],
          )),
        ],
      ),

    );
  }
}

class DiorTheCat extends StatelessWidget {
  const DiorTheCat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircleAvatar(
          radius: 32,
          backgroundImage: AssetImage('assets/images/dior1.jpg'),

        ),
        SizedBox(width: 12,),
        Text('Dior The Cat', style: TextStyle(fontWeight: FontWeight.w900),),
      ],
    );
  }
}

