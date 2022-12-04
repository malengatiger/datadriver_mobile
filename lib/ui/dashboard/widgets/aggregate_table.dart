import 'package:flutter/material.dart';

import 'package:flutter_web_data_table/web_data_table.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../../../data_models/city_aggregate.dart';
import '../../../utils/util.dart';

class CityAggregateTable extends StatefulWidget {
  const CityAggregateTable({Key? key, required this.aggregates,
    required this.sortBy, required this.onSelected}) : super(key: key);
  final List<CityAggregate> aggregates;
  final int sortBy;
  final Function(CityAggregate) onSelected;

  @override
  State<CityAggregateTable> createState() => _CityAggregateTableState();
}

const sortByAmount = 0;
const sortByName = 1;
const sortByEvents = 2;
const sortByRating = 3;

class _CityAggregateTableState extends State<CityAggregateTable> {
  var mSort = 0;
  var rows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    sort(widget.sortBy);
  }
  @override
  Widget build(BuildContext context) {
    var f = NumberFormat.compact();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: WebDataTable(
          header: const Text(
            'City Aggregates',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          // columnSpacing: 1,
          source: WebDataTableSource(
            columns: [
              WebDataColumn(
                name: 'cityName',
                label: InkWell(
                  onTap: (){
                    sort(1);
                  },
                  child: Text('CITY', style: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.w900),),
                ),
                dataCell: (value) => DataCell(Text('$value')),
              ),
              WebDataColumn(
                  name: 'averageRating',
                  label:  InkWell(
                    onTap: () {
                      sort(2);
                    },
                    child: Text('RATING',style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900),),
                  ),
                  dataCell: (value) {
                    double m = double.parse('$value');
                    return DataCell(Text(
                      m.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.blue),
                    ));
                  }),
              WebDataColumn(
                  name: 'totalSpent',
                  label: InkWell(
                    onTap: () {
                      sort(0);
                    },
                    child: Text('AMOUNT', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900),),
                  ),
                  dataCell: (value) {
                    double m = double.parse('$value');
                    return DataCell(Text(
                      f.format(m),
                        style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodyMedium, fontWeight: FontWeight.w900),
                    ));
                  }),
              WebDataColumn(
                  name: 'numberOfEvents',
                  label:  InkWell(
                    onTap: () {
                      sort(3);
                    },
                    child: Text('EVENTS', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900),),
                  ),
                  dataCell: (value) {
                    int m = int.parse('$value');
                    return DataCell(Text(f.format(m)));
                  }),
              WebDataColumn(
                name: 'date',
                label: Text('DATE', style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    fontWeight: FontWeight.w900),),
                dataCell: (value) => DataCell(Text('$value')),
              ),
              WebDataColumn(
                name: 'hours',
                label:  Text('MINUTES',style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    fontWeight: FontWeight.w900),),
                dataCell: (value) => DataCell(Text('$value', style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    fontWeight: FontWeight.w900),)),
                sortable: false,
              ),
            ],
            rows: rows,
            onTapRow: (rows, index) {
              p('$redDot onTapRow(): index = $index, row = ${rows[index]}');
              widget.onSelected(widget.aggregates.elementAt(index));
            },
            primaryKeyName: 'cityId',
          ),
          horizontalMargin: 100,
          onPageChanged: (offset) {
            p('$redDot onPageChanged(): offset = $offset');
          },
          onRowsPerPageChanged: (rowsPerPage) {
            p('$redDot onRowsPerPageChanged(): rowsPerPage = $rowsPerPage');
          },
          rowsPerPage: 20,
        ),
      ),
    );
  }

  void sort(int sortBy) {
    rows.clear();
    switch(sortBy) {
      case 0:
        widget.aggregates.sort((a,b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case 1:
        widget.aggregates.sort((a,b) => a.cityName.compareTo(b.cityName));
        break;
      case 2:
        widget.aggregates.sort((a,b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 3:
        widget.aggregates.sort((a,b) => b.numberOfEvents.compareTo(a.numberOfEvents));
        break;
    }

    for (var agg in widget.aggregates) {
      rows.add(agg.toJson());
    }
    setState(() {

    });
  }
}
