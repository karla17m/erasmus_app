import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_details_screen.dart';
import 'create_event_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events for You'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No events found"));
          }

          final events = snapshot.data!.docs;
          Map<String, List<QueryDocumentSnapshot>> groupedEvents = {};

          // Grupăm evenimentele pe lună
          for (var event in events) {
            final date = event['Date'] ?? '';
            if (date.isNotEmpty) {
              final parsedDate = DateTime.parse(date); // Convertim stringul în DateTime
              final monthYear = DateFormat('MMMM yyyy').format(parsedDate); // Formatăm ca "May 2023"
              groupedEvents.putIfAbsent(monthYear, () => []).add(event);
            }
          }

          return ListView(
            children: groupedEvents.entries.map((entry) {
              final monthYear = entry.key;
              final eventDocs = entry.value;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthYear,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    ...eventDocs.map((event) {
                      return ListTile(
                        title: Text(event['Title'] ?? 'No title'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailsScreen(
                                eventId: event.id,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateEventScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
