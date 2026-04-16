// lib/main.dart


import 'package:flutter/material.dart';
import 'package:kongossa/screens/storywindows/stories_widget.dart';
import 'package:kongossa/screens/storywindows/story2.0.dart';

import '../../model/datamodel/storyModels.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StoryModel> stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  void _loadStories() {
    stories = [
      StoryModel(
        id: '1',
        userName: 'john_doe',
        userAvatar: 'https://randomuser.me/api/portraits/men/1.jpg',
        stories: [
          StoryItem(
            id: '1_1',
            mediaUrl: 'https://picsum.photos/id/1/200/300',
            mediaType: StoryMediaType.image,
            caption: 'Beautiful sunset! 🌅',
          ),
          StoryItem(
            id: '1_2',
            mediaUrl: 'https://picsum.photos/id/2/200/300',
            mediaType: StoryMediaType.image,
            caption: 'Amazing view! 🏔️',
          ),
        ],
      ),
      StoryModel(
        id: '2',
        userName: 'jane_smith',
        userAvatar: 'https://randomuser.me/api/portraits/women/1.jpg',
        stories: [
          StoryItem(
            id: '2_1',
            mediaUrl: 'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4',
            mediaType: StoryMediaType.video,
            duration: Duration(seconds: 10),
          ),
          StoryItem(
            id: '2_2',
            mediaUrl: 'https://picsum.photos/id/3/200/300',
            mediaType: StoryMediaType.image,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StoriesviewWidgets(story: stories,),
    );
  }
}