import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../sevice/controlleur/publish_element/PublishControlleur.dart';
import 'create_post_widget.dart';


class CreatePostPremiumView extends GetView<CreatePostPremiumController> {
  const CreatePostPremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Scaffold(
              appBar: _buildAppBar(),
              body: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 2.h),
                            const PremiumUserHeader(),
                            SizedBox(height: 2.h),
                            const PremiumTextField(),
                            const PremiumMediaGallery(),
                            const PremiumOptions(),
                            const SelectedFeeling(),
                            const AdvancedSettings(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: const ActionBar(),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: const Text(
          'Nouvelle Publication',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Obx(
                () => _buildCharacterCounter(),
          ),
        ),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildCharacterCounter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: controller.charCount.value / controller.maxChars.value,
            strokeWidth: 3,
            backgroundColor: Colors.grey[800],
            color: controller.getCharacterCounterColor(),
          ),
        ),
        Text(
          '${controller.getRemainingChars()}',
          style: TextStyle(
            color: controller.getCharacterCounterColor(),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}