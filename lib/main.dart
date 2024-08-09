import 'dart:developer';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:objectbox/objectbox.dart';
import 'User.dart';
import 'objectbox.g.dart';

void main() async {
  // Initialize ObjectBox store
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openStore();
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store store;

  const MyApp({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(store: store),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Store store;

  const MyHomePage({Key? key, required this.store}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Controller to handle PageView and also handles initial page
  final _pageController = PageController(initialPage: 0);

  /// Controller to handle bottom nav bar and also handles initial page
  final NotchBottomBarController _controller = NotchBottomBarController(index: 0);

  int maxCount = 3;

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// widget list
    final List<Widget> bottomBarPages = [
      Page1(
        controller: (_controller),
          store: widget.store
      ),
       Page2(store: widget.store),
       Page3(store: widget.store),
    ];
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(bottomBarPages.length, (index) => bottomBarPages[index]),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
        /// Provide NotchBottomBarController
        notchBottomBarController: _controller,
        color: Color.fromRGBO(175, 225, 175, 1),
        showLabel: true,
        textOverflow: TextOverflow.visible,
        maxLine: 1,
        shadowElevation: 5,
        kBottomRadius: 28.0,

        // notchShader: const SweepGradient(
        //   startAngle: 0,
        //   endAngle: pi / 2,
        //   colors: [Colors.red, Colors.green, Colors.orange],
        //   tileMode: TileMode.mirror,
        // ).createShader(Rect.fromCircle(center: Offset.zero, radius: 8.0)),
        notchColor: Colors.white,

        /// restart app if you change removeMargins
        removeMargins: false,
        bottomBarWidth: 500,
        showShadow: false,
        durationInMilliSeconds: 300,

        itemLabelStyle: const TextStyle(fontSize: 10),

        elevation: 1,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.home_filled,
              color: Colors.white,
            ),
            activeItem: Icon(
              Icons.home_filled,
              color: Color.fromRGBO(109, 151, 115,1),
            ),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.add_to_photos, color: Colors.white),
            activeItem: Icon(
              Icons.add_to_photos,
              color: Color.fromRGBO(109, 151, 115,1),
            ),
            itemLabel: 'Add',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.person,
              color: Colors.white,
            ),
            activeItem: Icon(
              Icons.person,
              color: Color.fromRGBO(109, 151, 115,1),
            ),
            itemLabel: 'Profile',
          ),
        ],
        onTap: (index) {
          log('current selected index $index');
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0,
      )
          : null,
    );
  }
}

class Page1 extends StatefulWidget {
  final NotchBottomBarController? controller;
  final Store store;

  const Page1({Key? key, this.controller, required this.store}) : super(key: key);

  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  late Box<User> userBox;
  late List<User> users;

  @override
  void initState() {
    super.initState();
    userBox = widget.store.box<User>();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      users = userBox.getAll();
      users.sort((a, b) {
        final int currentDay = DateTime.now().day;
        final int dayA = int.tryParse(a.date.split('/').last) ?? 0;
        final int dayB = int.tryParse(b.date.split('/').last) ?? 0;

        if (dayA == currentDay && dayB != currentDay) {
          return -1;
        } else if (dayA != currentDay && dayB == currentDay) {
          return 1;
        } else {
          return dayA.compareTo(dayB);
        }
      });
    });
  }

  void _deleteUser(int id) {
    userBox.remove(id);
    _refreshUsers();
  }

  void _editUser(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user, userBox: userBox),
      ),
    );

    if (result == true) {
      _refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentDay = DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: Text('DAY  $currentDay',style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold,fontSize: 30)),
      ),
      body: users.isEmpty
          ? Center(child: Text('No subscriptions found'))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final int dayOfMonth = int.tryParse(user.date.split('/').last) ?? 0;
          final bool isToday = dayOfMonth == currentDay;
          double opacity=1.0;
          // Calculate opacity based on how far the date is from today
          if( dayOfMonth>currentDay) {
            opacity = 1.0 - (dayOfMonth - currentDay) / 30.0;
            opacity = opacity.clamp(
                0.4, 1.0); // Ensure opacity is between 0.4 and 1.0
          }
          return Slidable(
            key: ValueKey(user.id),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    _deleteUser(user.id);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    _editUser(user);
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  icon: Icons.edit,
                  label: 'Edit',
                ),
              ],
            ),
            child: Card(
              margin: const EdgeInsets.all(8.0),
              color: isToday
                  ? Colors.red?.withOpacity(opacity)
                  : currentDay>dayOfMonth?Color.fromRGBO(175, 225, 175,1):Color.fromRGBO(255, 140, 140, opacity),
              child: ListTile(
                title: Text(user.name,style: TextStyle(color: Colors.black),),
                subtitle: Text('Price: ₹${user.price}\nDay: ${user.date.substring(user.date.length-2,user.date.length)}',style: TextStyle(color: Colors.black),),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditUserScreen extends StatefulWidget {
  final User user;
  final Box<User> userBox;

  EditUserScreen({Key? key, required this.user, required this.userBox}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _priceController = TextEditingController(text: widget.user.price);
    _dateController = TextEditingController(text: widget.user.date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('20' + widget.user.date.replaceAll('/', '-')),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        final String formattedDate = "${picked.year % 100}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";
        _dateController.text = formattedDate;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Subscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Edit Subscription",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.lightGreen[100],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.lightGreen[100],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.lightGreen[100],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Billing Date (YY/MM/DD)",
                  border: InputBorder.none,
                ),
                onTap: () => _selectDate(context),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final price = _priceController.text.trim();
                final date = _dateController.text.trim();

                if (name.isEmpty || price.isEmpty || date.isEmpty) {
                  _showSnackbar("All fields must be filled.");
                  return;
                }

                widget.user.name = name;
                widget.user.price = price;
                widget.user.date = date;

                widget.userBox.put(widget.user);

                Navigator.pop(context, true);
                _showSnackbar("Subscription updated successfully.");
              },
              child: Text("EDIT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Page2 extends StatefulWidget {
  final Store store;

  Page2({Key? key, required this.store}) : super(key: key);

  @override
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        final String formattedDate = "${picked.year % 100}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";
        _dateController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userBox = widget.store.box<User>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "ADD SUBSCRIPTIONS",
          style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold,fontSize: 25),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.lightGreen[100],
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.lightGreen[100],
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: "Price",
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.lightGreen[100],
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Billing Date (YY/MM/DD)",
                border: InputBorder.none,
              ),
              onTap: () => _selectDate(context),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final price = _priceController.text.trim();
              final date = _dateController.text.trim();

              if (name.isEmpty || price.isEmpty || date.isEmpty) {
                _showSnackbar("All fields must be filled.");
                return;
              }

              final user = User(name: name, price: price, date: date);
              userBox.put(user);

              _nameController.clear();
              _priceController.clear();
              _dateController.clear();

              _showSnackbar("Subscription added successfully.");
            },
            child: Text("SUBMIT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[100],
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  final Store store;

  const Page3({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userBox = store.box<User>();
    final users = userBox.getAll();

    double totalCost = 0.0;
    final upcomingSubscriptions = <User>[];
    final lateSubscriptions = <User>[];

    // Get current day of the month
    final int currentDay = DateTime.now().day;

    for (var user in users) {
      totalCost += double.tryParse(user.price) ?? 0.0;

      // Extract day from the user date
      final int subscriptionDay = int.tryParse(user.date.split('/').last) ?? 0;

      // Compare only the day
      if (subscriptionDay >= currentDay) {
        upcomingSubscriptions.add(user);
      } else {
        lateSubscriptions.add(user);
      }
    }

    return Scaffold(
      /*appBar: AppBar(
        title: Text('SUMMARY',style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),*/
      body: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40,),
            Text("TOTAL",style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold,fontSize: 20)),
            Flexible(
              flex: 1,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 170, 170, 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                   
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: totalCost),
                      duration: Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Text(
                          " ₹ ${value.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 35),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5,),
            Text("UPCOMING",style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold,fontSize: 20)),
            Flexible(
              flex: 2,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(175, 225, 175,1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: upcomingSubscriptions.length,
                  itemBuilder: (context, index) {
                    final user = upcomingSubscriptions[index];
                    return Card(
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text('Price: ₹${user.price}\nBilling Day: ${user.date.substring(user.date.length-2,user.date.length)}'),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 5,),
            Text("LATE",style: TextStyle(color: Color.fromRGBO(79, 121, 66, 1),fontWeight: FontWeight.bold,fontSize: 20)),
            Flexible(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 170, 170, 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: lateSubscriptions.length,
                  itemBuilder: (context, index) {
                    final user = lateSubscriptions[index];
                    return Card(
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text('Price: ₹${user.price}\nBilling Day: ${user.date.substring(user.date.length-2,user.date.length)}'),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 75),
          ],
        ),
      ),
    );
  }
}





