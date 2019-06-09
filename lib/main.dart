import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final PageController ctrl = PageController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FirestoreSlideShow(),
      )
    );
  }
}

class FirestoreSlideShow extends StatefulWidget {
  createState() => FirestoreSlideShowState();
}

class FirestoreSlideShowState extends State<FirestoreSlideShow> {
  final PageController ctrl = PageController(viewportFraction: 0.8);

  final Firestore db = Firestore.instance;
  Stream slides;

  String activeTag = 'favorites';

  // Keep track of current page to avoid unnecessary renders
  int currentPage = 0;

  @override
  void initState() {
    _queryDb();

    // set state when page changes
    ctrl.addListener(() {
      int next = ctrl.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: slides,
      initialData: [],
      builder: (context, AsyncSnapshot snap) {
        List slideList = snap.data.toList();
        return PageView.builder(
          controller: ctrl,
          itemCount: slideList.length + 1, // represents the initial page that it will show in the page view
          itemBuilder: (context, int currentIdx) {
            if (currentIdx == 0) {
              return _buildTagPage();
            } else if (slideList.length >= currentIdx) {
              // active page
              bool active = currentIdx == currentPage;
              return _buildStoryPage(slideList[currentIdx - 1], active);
            }
          }
        );
      }
    );
  }

  Stream _queryDb({ String tag = 'favorites' }) {
    // make a query
    Query query = db.collection('stories').where('tags', arrayContains: tag);

    // map the documents to the data payload
    slides = query.snapshots().map((list) => list.documents.map((doc) => doc.data));

    // update the active tag
    setState(() {
      activeTag = tag;
    });
  }

  // builder functions
  _buildStoryPage(Map data, bool active) {
    // animated properties
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;


    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(data['img'])
        ),
        boxShadow: [BoxShadow(
          color: Colors.black87,
          blurRadius: blur,
          offset: Offset(offset, offset)
        )]
      )
    );
  }

   _buildButton(tag) {
    Color color = tag == activeTag ? Colors.purple : Colors.white;
    return FlatButton(
      color: color,
      child: Text('#$tag'),
      onPressed: () => _queryDb(tag: tag)
    );
  }

   _buildTagPage() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'your stories',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold
            )
          ),
          Text(
            'FILTER',
            style: TextStyle(
              color: Colors.black26
            )
          ),
          _buildButton('favorites'),
          _buildButton('happy')
        ],
      ),
    );
  }
}
