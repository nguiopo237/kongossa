import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kongossa/config_App/colorsApp.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../model/menu.dart';
import '../../../presentation/component/style/custum_text.dart';
import '../../../presentation/component/widget/select_media.dart';
import '../../../presentation/component/widget/widget_component.dart';
import '../../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../../utils/rive_utils.dart';
import 'info_card.dart';
import 'side_menu.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 288,
        height: double.infinity,
        decoration:  BoxDecoration(
          color: ColorApp.primary5.withOpacity(0.8),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  StreamBuilder(
                    stream: Users.where('googleId', isEqualTo: AppUser.info?.googleId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Erreur : ${snapshot.error}');
                      } else if (!snapshot.hasData) {
                        return Text('Pas de données disponibles');
                      } else {
                        final document = snapshot.data!.docs.first;
                        return FittedBox(
                          fit: BoxFit.contain,
                          child: Container(
                            width: 288,
                            // height: double.infinity,
                            decoration:  BoxDecoration(
                              color: ColorApp.primary5.withOpacity(0.8),
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                            ),
                            child: DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      InfoCard(
                                        name: "${document["name"]}",
                                        bio: "${document["email"]}",
                                        image: "${document["photoUrl"]}",
                                      ),
                                      Positioned(
                                        bottom: 1.h,

                                        // left: 2.w,
                                        // top: 1.w,
                                        left: 10.w,

                                        child: InkWell(
                                          onTap: () async {
                                            WidgetComponent.getmodal(
                                              sectionview: Container(
                                                height: 60.h,
                                                child: PremiumMediaSelector(
                                                  onSourceSelected:
                                                      (MediaSource p1) {},
                                                ),
                                              ),
                                            );
                                          },
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: ColorApp.primary2.withOpacity(0.5),
                                            child: Icon(
                                              Icons.upload,
                                              size: 12,
                                              color: ColorApp.primary1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                child: CustomText(
                  "Browse".toUpperCase(),
                  type: TextType.headlineSmall,
                  style: TextStyle(color: ColorApp.primary3,fontWeight: FontWeight.bold),
                ),
                // child: Text(
                //   "Browse".toUpperCase(),
                //   style: Theme.of(context)
                //       .textTheme
                //       .titleMedium!
                //       .copyWith(color: ColorApp.primary3),
                // ),
              ),
              ...sidebarMenus.map(
                (menu) => PremiumSideMenu(
                  menu: menu,
                  selectedMenu: selectedSideMenu,
                  press: () {
                    RiveUtils.chnageSMIBoolState(menu.rive.status!);
                    setState(() {
                      selectedSideMenu = menu;
                    });
                  },
                  riveOnInit: (artboard) {
                    menu.rive.status = RiveUtils.getRiveInput(
                      artboard,
                      stateMachineName: menu.rive.stateMachineName,
                    );
                  },
                  index: sidebarMenus.indexOf(menu),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                child: CustomText(
                  "History".toUpperCase(),
                  type: TextType.headlineSmall,
                  style: TextStyle(color: ColorApp.primary3),
                ),

                // Text(
                //   "History".toUpperCase(),
                //   style: Theme.of(context)
                //       .textTheme
                //       .titleMedium!
                //       .copyWith(color: ColorApp.primary3),
                // ),
              ),
              ...sidebarMenus2.map(
                (menu) => PremiumSideMenu(
                  menu: menu,
                  selectedMenu: selectedSideMenu,
                  press: () {
                    RiveUtils.chnageSMIBoolState(menu.rive.status!);
                    setState(() {
                      selectedSideMenu = menu;
                    });
                  },
                  riveOnInit: (artboard) {
                    menu.rive.status = RiveUtils.getRiveInput(
                      artboard,
                      stateMachineName: menu.rive.stateMachineName,
                    );
                  },
                  index: sidebarMenus2.indexOf(menu),
                ),
              ),
              // Flex(direction: direction)
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary2
                    ),
                    onPressed: () {
                      authController.getdelete();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomText(
                          "Deconnexion".toUpperCase(),
                          type: TextType.headlineSmall,
                          style:

                          TextStyle(
                            color: ColorApp.foreground,
                            fontWeight:
                            FontWeight.w600,
                            fontSize: 16.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.logout,color: ColorApp.foreground,),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
