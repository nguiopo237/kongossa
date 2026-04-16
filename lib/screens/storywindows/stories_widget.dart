import 'package:flutter/material.dart';
import 'package:kongossa/screens/storywindows/story2.0.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config_App/colorsApp.dart';
import '../../model/datamodel/storyModels.dart';
import '../../model/datamodel/user_model.dart';
import '../../presentation/component/widget/add_story.dart';
import '../../presentation/component/widget/builoption.dart';
import '../../presentation/component/widget/widget_component.dart';
import '../../sevice/controlleur/publish_element/PublishControlleur.dart';

class StoriesviewWidgets extends StatelessWidget {
  List<StoryModel>story;
  StoriesviewWidgets({super.key,required this.story});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start ,
      children: [
        // Header
        Container(
          // padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Stories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Row(
              //   children: const [
              //     Icon(Icons.add_box_outlined),
              //     SizedBox(width: 20),
              //     Icon(Icons.messenger_outlined),
              //   ],
              // ),
            ],
          ),
        ),

        // Stories Widget
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // HomeScreen(),
                  StoryCircle(
                    onTap: () {},
                    userStory: UserStory(
                      userId: AppUser.info!.googleId,
                      username: AppUser.info!.displayName,
                      userAvatarUrl: AppUser.info!.photoUrl!,
                      stories: [],
                    ),
                  ),
                  Positioned(
                    bottom: 1.h,
                    right: 3.w,
                    child: InkWell(
                      onTap: () {
                        WidgetComponent.getmodal(
                          sectionview: Row(
                            children: [
                              Expanded(
                                child: Builoption(
                                  icon: Icons.photo_camera,
                                  label: 'Photo',
                                  onTap: () => c.addImagestory(),
                                  isActive: true,
                                  // isActive: controller.attachedImages.isNotEmpty,
                                  activeColor: Colors.green,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Builoption(
                                  icon: Icons.videocam,
                                  label: 'video',
                                  onTap: () => null,
                                  isActive: true,
                                  // isActive: controller.attachedImages.isNotEmpty,
                                  activeColor: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 1.7.h,
                        child: Icon(Icons.add, color: Colors.red),
                        backgroundColor: ColorApp.primary1,
                      ),
                    ),
                  ),
                ],
              ),
              // if(story.isNotEmpty)
              StoriesWidget(
                stories: story,
                onStoryTap: (story) {
                  print('Story tapped: ${story.userName}');
                },
                onStoryLongPress: (story) {
                  print('Story long pressed: ${story.userName}');
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h,),

        const Divider(height: 1),

        // Contenu principal (feed, etc.)
        // Expanded(
        //   child: Center(
        //     child: Text('Feed content here'),
        //   ),
        // ),
      ],
    );
  }
}
