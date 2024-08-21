import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nearco/inside/dashboard.dart';
import 'package:nearco/inside/detail_event.dart';
import 'package:nearco/navigation_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearco/auth/login.dart';
import 'package:nearco/inside/detail_news.dart';

class Event extends StatefulWidget {
  const Event({Key? key}) : super(key: key);

  @override
  State<Event> createState() => _EventState();
}

class _EventState extends State<Event> {
  String username = ''; // Initialize with the logged-in user's data
  String email = ''; // Initialize with the logged-in user's data
  String password = ''; // Initialize with the logged-in user's data
  List<dynamic> eventList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getProductData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      email = prefs.getString('email') ?? '';
      password = prefs.getString('password') ?? '';
    });
  }

  Future<void> getProductData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(Uri.parse('https://mitrasite.com/nearco/api/tampil-event.php'));

      if (response.statusCode == 200) {
        setState(() {
          eventList = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load News');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching news: $e');
    }
  }

  Future<void> handleRefresh() async {
    await getProductData();
  }

  void navigateToDetaiEvent(String idEvent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailEvent(idEvent: idEvent),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final String apiUrl = 'https://mitrasite.com/nearco/api/logout.php';
    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'username': username,
        'email': email,
        'password': password,
      });
      final result = json.decode(response.body);
      if (result['status'] == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Clear all saved user data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Login(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['message']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed : ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(48, 56, 65, 1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => NavigationMenu(),
              ),
            );
          },
        ),
        title: Image.asset(
          'assets/logo_nearco.png',
          height: 70,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.white,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        color: Colors.grey,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(color: Colors.grey),
                  )
                else if (eventList.isEmpty)
                  Center(
                    child: Text('No Event found'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: eventList.length,
                    itemBuilder: (BuildContext context, int index) {
                      var event = eventList[index];
                      return GestureDetector(
                        onTap: () {
                          navigateToDetaiEvent(event['id_event']);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.grey[200],
                          ),
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'https://mitrasite.com/nearco/app/foto_event/${event['foto']}',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                event['nama'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                event['deskripsi'].length > 200
                                    ? '${event['deskripsi'].substring(0, 200)}...'
                                    : event['deskripsi'],
                                style: TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
