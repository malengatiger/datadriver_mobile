import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key, required this.onSelected, this.backgroundColor}) : super(key: key);
  final Function(int) onSelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: backgroundColor?? Colors.brown[50],
      child: Column(
        children: [
          Card(
            elevation: 4,
              child: Image.asset('assets/images/m2.jpg', fit: BoxFit.fill,)),
          const SizedBox(height: 8,),
           Text('Data is good to play with, Senor!', style: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.normal),
              ),
          const SizedBox(height: 60,),
          Expanded(child: ListView(
            children:  [
              ListTile(
                leading: const Icon(Icons.dashboard),
                title:  Text('Dashboard',style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  onSelected(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title:  Text('City Aggregated Data',style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  onSelected(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title:  Text('City Maps',style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  onSelected(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.generating_tokens),
                title:  Text('Data Generation',style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.normal),
                ),
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

