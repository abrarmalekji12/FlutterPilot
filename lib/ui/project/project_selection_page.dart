import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:lottie/lottie.dart';

import '../../common/app_button.dart';
import '../../common/app_loader.dart';
import '../../common/common_methods.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/extension_util.dart';
import '../../common/firebase_image.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../../constant/string_constant.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../injector.dart';
import '../../models/project_model.dart';
import '../../screen_model.dart';
import '../../user_session.dart';
import '../../widgets/button/app_action_button.dart';
import '../../widgets/flutterpilot_logo.dart';
import '../../widgets/image/profile_dynamic_image.dart';
import '../../widgets/loading/overlay_loading_component.dart';
import '../authentication/auth_navigation.dart';
import '../common/custom_shimmer.dart';
import '../component_tree/component_tree.dart';
import '../navigation/animated_dialog.dart';
import '../create_screen_dialog.dart';
import '../settings/models/collaborator.dart';
import '../template_upload_widget.dart';
import 'create_project_widget.dart';

class FVBMenuItem {
  final String name;
  final IconData icon;

  const FVBMenuItem(this.name, this.icon);
}

class ProjectSelectionPage extends StatefulWidget {
  final String userId;

  const ProjectSelectionPage({Key? key, required this.userId})
      : super(key: key);

  @override
  _ProjectSelectionPageState createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  late final UserDetailsCubit _userDetailsCubit;
  late final AuthenticationCubit _authenticationCubit;
  final List<String> projectNameList = [];
  final ValueNotifier<FVBMenuItem> _fvbMenuItemNotifier =
      ValueNotifier(fvbMenuItems.first);
  final _userSession = sl<UserSession>();

  @override
  void initState() {
    super.initState();
    _userDetailsCubit = context.read<UserDetailsCubit>();
    _authenticationCubit = context.read<AuthenticationCubit>();
    _authenticationCubit.initial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background1,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: BlocListener<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            switch (state.runtimeType) {
              case AuthLoadingState:
                break;
              case AuthLoginSuccessState:
                AppLoader.hide(context);
                break;
              case AuthLogoutSuccessState:
                Navigator.pushReplacementNamed(context, '/login');
                break;
            }
          },
          child: BlocListener<UserDetailsCubit, UserDetailsState>(
            bloc: _userDetailsCubit,
            listener: (context, state) {
              switch (state) {
                case (UserDetailsErrorState state):
                  showConfirmDialog(
                    context: context,
                    title: 'Error',
                    subtitle: state.message,
                    positive: 'Ok',
                  );
                case (FlutterProjectLoadingErrorState state):
                  showConfirmDialog(
                    context: context,
                    title: 'Error',
                    subtitle:
                        '${state.model.projectLoadError.name}: ${state.model.error ?? ''}',
                    positive: 'Ok',
                  );
                  break;
              }
            },
            child: Stack(
              children: [
                const Positioned.fill(child: BackgroundNetAnimation()),
                Container(
                  color: theme.background1.withOpacity(0.5),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 250,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.border1,
                              ),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Hero(
                                tag: 'pilot_logo',
                                child: FlutterPilotMediumLogo(),
                              ),
                              Expanded(
                                child: RootNavigationWidget(
                                  onChange: _fvbMenuItemNotifier,
                                ),
                              ),
                              20.hBox,
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.background2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ProfileDynamicImage(
                                      userName: _userSession.user.email,
                                      radius: 18,
                                    ),
                                    10.wBox,
                                    Expanded(
                                        child: Column(
                                      children: [
                                        Text(
                                          _userSession.user.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFontStyle.lato(
                                            14,
                                            fontWeight: FontWeight.w600,
                                            color: theme.text2Color,
                                          ),
                                        )
                                      ],
                                    ))
                                  ],
                                ),
                              ),
                              20.hBox,
                              const LogoutButton(),
                            ],
                          ),
                        ),
                        20.wBox,
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: _fvbMenuItemNotifier,
                            builder: (context, value, _) => IndexedStack(
                              index: fvbMenuItems.indexOf(value),
                              children: [
                                const ProjectListingsWidget(),
                                const MyTemplatesWidget(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyTemplatesWidget extends StatefulWidget {
  const MyTemplatesWidget({super.key});

  @override
  State<MyTemplatesWidget> createState() => _MyTemplatesWidgetState();
}

class _MyTemplatesWidgetState extends State<MyTemplatesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Templates',
            style: AppFontStyle.headerStyle(),
          ),
          20.hBox,
          const Expanded(
            child: TemplateSelectionWidget(
              selection: false,
            ),
          )
        ],
      ),
    );
  }
}

class ProjectListingsWidget extends StatefulWidget {
  const ProjectListingsWidget({super.key});

  @override
  State<ProjectListingsWidget> createState() => _ProjectListingsWidgetState();
}

class _ProjectListingsWidgetState extends State<ProjectListingsWidget> {
  final UserDetailsCubit _userDetailsCubit = sl();
  final UserSession _userSession = sl();

  @override
  void initState() {
    AppLoader.hide(context);
    _userDetailsCubit.loadProjectList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _userDetailsCubit,
      child: BlocListener(
        bloc: _userDetailsCubit,
        listener: (context, state) {
          switch (state.runtimeType) {
            case UserDetailsLoadedState:
              setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your projects',
                    style: AppFontStyle.headerStyle(),
                    textAlign: TextAlign.left,
                  ),
                  AppActionButton(
                    text: 'Create Project',
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 18),
                    onPressed: () {
                      AnimatedDialog.show(
                          context,
                          ProjectCreationDialog(
                            projects: _userSession.settingModel!.projects
                                .map((e) => e.name)
                                .toList(),
                            userId: _userDetailsCubit.userId!,
                            onCreated: (FVBProject project) async {
                              if (project.screens.isEmpty) {
                                final cubit = context.read<ScreenConfigCubit>();
                                selectedConfig = cubit.screenConfigs.first;
                                await showScreenCreationDialog(context);
                              }
                              Navigator.pushReplacementNamed(
                                  context, '/projects',
                                  arguments: [project.userId, project.id]);
                            },
                          ),
                          barrierDismissible: true);
                    },
                    icon: Icons.add,
                    backgroundColor: ColorAssets.theme,
                  ),
                ],
              ),
              20.hBox,
              Expanded(
                child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
                  builder: (context, state) {
                    if (state is ProjectListLoadingState) {
                      return GridView.builder(
                        clipBehavior: Clip.none,
                        itemCount: 8,
                        itemBuilder: (context, i) => CustomShimmer(
                            child: Container(
                          margin: const EdgeInsets.only(right: 10, bottom: 10),
                          decoration: BoxDecoration(
                            color: ColorAssets.shimmerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                        )),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 450,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 100),
                      );
                    }
                    if (_userSession.settingModel?.projects.isEmpty ?? true) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                Images.emptyProjects,
                                height: 250,
                                repeat: false,
                              ),
                              Text(
                                'No Projects',
                                style: AppFontStyle.lato(
                                  18.sp,
                                  fontWeight: FontWeight.normal,
                                  color: theme.text1Color.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return OverlayLoadingComponent(
                      loading: state is ProjectUpdateLoadingState,
                      radius: 0,
                      child: SizedBox(
                        width: double.infinity,
                        child: GridView.builder(
                          clipBehavior: Clip.none,
                          itemCount:
                              _userSession.settingModel?.projects.length ?? 0,
                          itemBuilder: (context, i) => ProjectTile(
                            id: _userDetailsCubit.userId!,
                            project: _userSession.settingModel!.projects[i],
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 300,
                          ),
                        ).animate().fadeIn(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectTile extends StatefulWidget {
  final FVBProject project;
  final String id;

  const ProjectTile({Key? key, required this.id, required this.project})
      : super(key: key);

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  final UserSession _userSession = sl();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 600),
          shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) => !states.contains(WidgetState.hovered)
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.border1),
                    )
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: ColorAssets.theme.withOpacity(0.5), width: 2),
                    )),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              !states.contains(WidgetState.hovered)
                  ? ColorAssets.theme.withOpacity(0)
                  : ColorAssets.theme.withOpacity(0.05)),
          elevation: const WidgetStatePropertyAll(0),
          foregroundColor: const WidgetStatePropertyAll(ColorAssets.theme),
          padding: WidgetStatePropertyAll(
            Responsive.isDesktop(context)
                ? const EdgeInsets.all(12)
                : const EdgeInsets.all(4),
          ),
          splashFactory: InkSparkle.splashFactory),
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          '/projects',
          arguments: [widget.id, widget.project.id],
        );
      },
      child: Container(
        width: !Responsive.isMobile(context)
            ? 550
            : (MediaQuery.of(context).size.width - 50) / 2,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.name,
                        style: AppFontStyle.lato(
                            Responsive.isDesktop(context) ? 16 : 14,
                            color: theme.text1Color,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        textAlign: TextAlign.left,
                      ),
                      8.hBox,
                      SizedBox(
                        height: 25,
                        child: Row(
                          children: [
                            for (final TargetPlatformType key in widget
                                .project.settings.target.entries
                                .where((element) => element.value)
                                .map((e) => e.key))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  key.icon,
                                  size: 16,
                                  color: theme.text2Color,
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppActionButton(
                        text: 'Run',
                        icon: Icons.play_arrow_rounded,
                        backgroundColor: ColorAssets.green,
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/run',
                              arguments: [widget.id, widget.project.id]);
                        }),
                    if (widget.project.userRole(_userSession) ==
                        ProjectPermission.owner) ...[
                      10.wBox,
                      CustomPopupMenuButton(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: theme.text1Color,
                          ),
                        ),
                        itemBuilder: (BuildContext context) => [
                          const CustomPopupMenuItem(
                            value: 0,
                            child: Text('Delete'),
                          ),
                          const CustomPopupMenuItem(
                            value: 1,
                            child: Text('Rename'),
                          )
                        ],
                        onSelected: (i) {
                          switch (i) {
                            case 0:
                              deleteProject(context, widget.project);
                              break;
                            case 1:
                              renameProject(context, widget.project);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            8.hBox,
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: ColorAssets.colorE5E5E5,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: FirebaseImage(
                  width: double.infinity,
                  ImageRef.projectThumbnail(widget.project),
                  errorBuilder: (context, _, __) {
                    return const Offstage();
                  },
                  fit: BoxFit.contain,
                ),
              ),
            ),
            8.hBox,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last updated ${widget.project.updatedAt == null ? 'long time' : DateTime.now().difference(widget.project.updatedAt!).showInHHMM(false)} ago',
                    style: AppFontStyle.lato(
                      isDesktop ? 13 : 12,
                      color: theme.text2Color,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Row(
                  children: [
                    for (final user in [
                      if (widget.project.userId !=
                          _userSession.user.userId) ...[
                        if (widget.project.user != null)
                          widget.project.user!.email
                      ] else
                        _userSession.user.email,
                      ...?widget.project.settings.collaborators
                          ?.map((e) => e.email),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Tooltip(
                            message: user,
                            child: ProfileDynamicImage(
                                userName: user, radius: 12)),
                      )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void deleteProject(BuildContext context, FVBProject project) {
  showConfirmDialog(
    title: 'Delete Project',
    subtitle:
        'Do you really want to delete "${project.name}", you will not be able to recover?',
    positive: 'delete',
    negative: 'cancel',
    onPositiveTap: () {
      context.read<UserDetailsCubit>().deleteProject(project);
    },
    context: context,
  );
}

void addToTemplates(BuildContext context, FVBProject project) {
  AnimatedDialog.show(
      context,
      TemplateUploadWidget(
        project: project,
      ));
}

void renameProject(BuildContext context, FVBProject project) {
  final _userSession = sl<UserSession>();
  showEnterInfoDialog(
    context,
    'Rename "${project.name}"',
    validator: (value) {
      if (value == project.name) {
        return 'Please enter different name';
      } else if (_userSession.settingModel!.projects
              .firstWhereOrNull((element) => element.name == value) !=
          null) {
        return 'Project with name "$value" already exist!';
      }
      return null;
    },
    initialValue: project.name,
    onPositive: (value) {
      context.read<UserDetailsCubit>().renameProject(project, value);
    },
  );
}

class DeleteIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteIconButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.delete,
      iconColor: Colors.red,
      background: Colors.white,
      onPressed: onPressed,
    );
  }
}

class EditIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditIconButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedAppIconButton(
      icon: Icons.edit,
      iconSize: 14,
      color: theme.background1,
      iconColor: theme.iconColor1,
      onPressed: onPressed,
    );
  }
}

class CopyIconButton extends StatelessWidget {
  final String text;

  const CopyIconButton({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.copy,
      iconColor: ColorAssets.grey,
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
      },
      background: theme.background1,
    );
  }
}

class RoundedAppIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double buttonSize;
  final VoidCallback onPressed;
  final Color color;
  final Color? iconColor;

  const RoundedAppIconButton(
      {Key? key,
      required this.icon,
      required this.onPressed,
      required this.color,
      this.iconColor,
      this.iconSize = 16,
      this.buttonSize = 24})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: kElevationToShadow[2]),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: iconSize,
        ),
      ),
      onTap: onPressed,
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showConfirmDialog(
          title: 'Logout',
          subtitle: 'Are you sure, you want to logout?',
          positive: 'Yes',
          negative: 'No',
          onPositiveTap: () {
            BlocProvider.of<AuthenticationCubit>(context).logout();
          },
          context: context,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout_rounded,
              color: theme.text2Color,
              size: 20,
            ),
            const SizedBox(
              width: 20,
            ),
            Text(
              'Logout',
              style: AppFontStyle.lato(15,
                  color: theme.text2Color, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}

class RootNavigationWidget extends StatefulWidget {
  final ValueNotifier<FVBMenuItem> onChange;

  const RootNavigationWidget({super.key, required this.onChange});

  @override
  State<RootNavigationWidget> createState() => _RootNavigationWidgetState();
}

const List<FVBMenuItem> fvbMenuItems = [
  FVBMenuItem('Projects', Icons.color_lens_outlined),
  FVBMenuItem('Templates', Icons.list_alt_outlined),
];

class _RootNavigationWidgetState extends State<RootNavigationWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 30),
      separatorBuilder: (_, i) => const SizedBox(
        height: 20,
      ),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ValueListenableBuilder(
            valueListenable: widget.onChange,
            builder: (context, _, __) {
              final selected = fvbMenuItems[index] == widget.onChange.value;
              return MaterialButton(
                color: selected ? ColorAssets.theme : theme.background3,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onPressed: () {
                  widget.onChange.value = fvbMenuItems[index];
                },
                child: Row(
                  children: [
                    Icon(
                      fvbMenuItems[index].icon,
                      size: 22,
                      color: selected
                          ? Colors.white
                          : theme.text1Color.withOpacity(0.7),
                    ),
                    20.wBox,
                    Text(
                      fvbMenuItems[index].name,
                      style: AppFontStyle.lato(
                        16,
                        color: selected
                            ? Colors.white
                            : theme.text1Color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            });
      },
      itemCount: fvbMenuItems.length,
    );
  }
}
