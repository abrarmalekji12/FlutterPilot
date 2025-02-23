// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../injector.dart';
import 'custom_menu_theme.dart';
import 'menu_button_theme.dart';
import 'menu_style.dart';

// Enable if you want verbose logging about menu changes.
const bool _kDebugMenus = false;

// The default size of the arrow in _MenuItemLabel that indicates that a menu
// has a submenu.
const double _kDefaultSubmenuIconSize = 24;

// The default spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 18;

// The minimum spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4;

// Navigation shortcuts that we need to make sure are active when menus are
// open.
const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts =
    <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown):
      DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      DirectionalFocusIntent(TraversalDirection.right),
};

// The minimum vertical spacing on the outside of menus.
const double _kMenuVerticalMinPadding = 4;

// How close to the edge of the safe area the menu will be placed.
const double _kMenuViewPadding = 8;

// The minimum horizontal spacing on the outside of the top level menu.
const double _kTopLevelMenuHorizontalMinPadding = 4;

/// The type of builder function used by [MenuAnchor.builder] to build the
/// widget that the [MenuAnchor] surrounds.
///
/// The `context` is the context that the widget is being built in.
///
/// The `controller` is the [CustomMenuController] that can be used to open and close
/// the menu with.
///
/// The `child` is an optional child supplied as the [MenuAnchor.child]
/// attribute. The child is intended to be incorporated in the result of the
/// function.
typedef MenuAnchorChildBuilder = Widget Function(
  BuildContext context,
  CustomMenuController controller,
  Widget? child,
);

/// A widget used to mark the "anchor" for a set of submenus, defining the
/// rectangle used to position the menu, which can be done either with an
/// explicit location, or with an alignment.
///
/// When creating a menu with [CustomMenuBar] or a [CustomSubmenuButton], a [MenuAnchor] is
/// not needed, since they provide their own internally.
///
/// The [MenuAnchor] is meant to be a slightly lower level interface than
/// [CustomMenuBar], used in situations where a [CustomMenuBar] isn't appropriate, or to
/// construct widgets or screen regions that have submenus.
///
/// {@tool dartpad}
/// This example shows how to use a [MenuAnchor] to wrap a button and open a
/// cascading menu from the button.
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_anchor.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to use a [MenuAnchor] to create a cascading context
/// menu in a region of the view, positioned where the user clicks the mouse
/// with Ctrl pressed. The [anchorTapClosesMenu] attribute is set to true so
/// that clicks on the [MenuAnchor] area will cause the menus to be closed.
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_anchor.1.dart **
/// {@end-tool}
class MenuAnchor extends StatefulWidget {
  /// Creates a const [MenuAnchor].
  ///
  /// The [menuChildren] argument is required.
  const MenuAnchor({
    super.key,
    this.controller,
    this.childFocusNode,
    this.style,
    this.alignmentOffset = Offset.zero,
    this.clipBehavior = Clip.none,
    this.anchorTapClosesMenu = false,
    this.closeOnOutsideClick = false,
    this.onOpen,
    this.onClose,
    required this.menuChildren,
    this.builder,
    this.child,
  });

  /// An optional controller that allows opening and closing of the menu from
  /// other widgets.
  final CustomMenuController? controller;

  /// The [childFocusNode] attribute is the optional [FocusNode] also associated
  /// the [child] or [builder] widget that opens the menu.
  ///
  /// The focus node should be attached to the widget that should receive focus
  /// if keyboard focus traversal moves the focus off of the submenu with the
  /// arrow keys.
  ///
  /// If not supplied, then keyboard traversal from the menu back to the
  /// controlling button when the menu is open is disabled.
  final FocusNode? childFocusNode;

  /// The [MenuStyle] that defines the visual attributes of the menu bar.
  ///
  /// Colors and sizing of the menus is controllable via the [MenuStyle].
  ///
  /// Defaults to the ambient [MenuThemeData.style].
  final CustomMenuStyle? style;

  /// The offset of the menu relative to the alignment origin determined by
  /// [MenuStyle.alignment] on the [style] attribute and the ambient
  /// [Directionality].
  ///
  /// Use this for adjustments of the menu placement.
  ///
  /// Increasing [Offset.dy] values of [alignmentOffset] move the menu position
  /// down.
  ///
  /// If the [MenuStyle.alignment] from [style] is not an [AlignmentDirectional]
  /// (e.g. [Alignment]), then increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the right.
  ///
  /// If the [MenuStyle.alignment] from [style] is an [AlignmentDirectional],
  /// then in a [TextDirection.ltr] [Directionality], increasing [Offset.dx]
  /// values of [alignmentOffset] move the menu position to the right. In a
  /// [TextDirection.rtl] directionality, increasing [Offset.dx] values of
  /// [alignmentOffset] move the menu position to the left.
  ///
  /// Defaults to [Offset.zero].
  final Offset? alignmentOffset;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// Whether the menus will be closed if the anchor area is tapped.
  ///
  /// For menus opened by buttons that toggle the menu, if the button is tapped
  /// when the menu is open, the button should close the menu. But if
  /// [anchorTapClosesMenu] is true, then the menu will close, and
  /// (surprisingly) immediately re-open. This is because tapping on the button
  /// closes the menu before the `onPressed` or `onTap` handler is called
  /// because of it being considered to be "outside" the menu system, and then
  /// the button (seeing that the menu is closed) immediately reopens the menu.
  /// The result is that the user thinks that tapping on the button does
  /// nothing. So, for button-initiated menus, this value is typically false so
  /// that the menu anchor area is considered "inside" of the menu system and
  /// doesn't cause it to close unless [CustomMenuController.close] is called.
  ///
  /// For menus that are positioned using [CustomMenuController.open]'s `position`
  /// parameter, it is often desirable that clicking on the anchor always closes
  /// the menu since the anchor area isn't usually considered part of the menu
  /// system by the user. In this case [anchorTapClosesMenu] should be true.
  ///
  /// Defaults to false.
  final bool anchorTapClosesMenu;
  final bool closeOnOutsideClick;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// A list of children containing the menu items that are the contents of the
  /// menu surrounded by this [MenuAnchor].
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final List<Widget> menuChildren;

  /// The widget that this [MenuAnchor] surrounds.
  ///
  /// Typically this is a button used to open the menu by calling
  /// [CustomMenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [MenuAnchor] will be the size that its parent
  /// allocates for it.
  final MenuAnchorChildBuilder? builder;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

  @override
  State<MenuAnchor> createState() => _MenuAnchorState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return menuChildren
        .map<DiagnosticsNode>((Widget child) => child.toDiagnosticsNode())
        .toList();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('anchorTapClosesMenu',
        value: anchorTapClosesMenu, ifTrue: 'AUTO-CLOSE'));
    properties
        .add(DiagnosticsProperty<FocusNode?>('focusNode', childFocusNode));
    properties.add(DiagnosticsProperty<CustomMenuStyle?>('style', style));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties
        .add(DiagnosticsProperty<Offset?>('alignmentOffset', alignmentOffset));
    properties.add(StringProperty('child', child.toString()));
  }
}

class _MenuAnchorState extends State<MenuAnchor> {
  // This is the global key that is used later to determine the bounding rect
  // for the anchor's region that the CustomSingleChildLayout's delegate
  // uses to determine where to place the menu on the screen and to avoid the
  // view's edges.
  final GlobalKey _anchorKey =
      GlobalKey(debugLabel: kReleaseMode ? null : 'MenuAnchor');
  _MenuAnchorState? _parent;
  bool _childIsOpen = false;
  final FocusScopeNode _menuScopeNode =
      FocusScopeNode(debugLabel: kReleaseMode ? null : 'MenuAnchor sub menu');
  CustomMenuController? _internalMenuController;
  final List<_MenuAnchorState> _anchorChildren = <_MenuAnchorState>[];
  ScrollPosition? _position;
  Size? _viewSize;
  OverlayEntry? _overlayEntry;
  Axis get _orientation => Axis.vertical;
  bool get _isOpen => _overlayEntry != null;
  bool get _isRoot => _parent == null;
  bool get _isTopLevel => _parent?._isRoot ?? false;
  CustomMenuController get _menuController =>
      widget.controller ?? _internalMenuController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = CustomMenuController();
    }
    _menuController._attach(this);
  }

  @override
  void dispose() {
    assert(_debugMenuInfo('Disposing of $this'));
    if (_isOpen) {
      _close(inDispose: true);
      _parent?._removeChild(this);
    }
    _anchorChildren.clear();
    _menuController._detach(this);
    _internalMenuController = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent?._removeChild(this);
    _parent = _MenuAnchorState._maybeOf(context);
    _parent?._addChild(this);
    _position?.isScrollingNotifier.removeListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _position = Scrollable.maybeOf(context)?.position;
      _position?.isScrollingNotifier.addListener(_handleScroll);
    });
    final Size newSize = MediaQuery.of(context).size;
    if (_viewSize != null && newSize != _viewSize) {
      // Close the menus if the view changes size.
      _root._close();
    }
    _viewSize = newSize;
  }

  @override
  void didUpdateWidget(MenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      if (widget.controller != null) {
        _internalMenuController?._detach(this);
        _internalMenuController = null;
        widget.controller?._attach(this);
      } else {
        assert(_internalMenuController == null);
        _internalMenuController = CustomMenuController().._attach(this);
      }
    }
    assert(_menuController._anchor == this);
    if (_overlayEntry != null) {
      // Needs to update the overlay entry on the next frame, since it's in the
      // overlay.
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _overlayEntry!.markNeedsBuild();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildContents(context);

    if (!widget.anchorTapClosesMenu) {
      child = child;
    }

    return _MenuAnchorMarker(
      anchorKey: _anchorKey,
      anchor: this,
      child: child,
    );
  }

  Widget _buildContents(BuildContext context) {
    return Builder(
      key: _anchorKey,
      builder: (BuildContext context) {
        if (widget.builder == null) {
          return widget.child ?? const SizedBox();
        }
        return widget.builder!(
          context,
          _menuController,
          widget.child,
        );
      },
    );
  }

  // Returns the first focusable item in the submenu, where "first" is
  // determined by the focus traversal policy.
  FocusNode? get _firstItemFocusNode {
    if (_menuScopeNode.context == null) {
      return null;
    }
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(_menuScopeNode.context!) ??
            ReadingOrderTraversalPolicy();
    return policy.findFirstFocus(
      _menuScopeNode,
    );
  }

  void _addChild(_MenuAnchorState child) {
    assert(_isRoot || _debugMenuInfo('Added root child: $child'));
    assert(!_anchorChildren.contains(child));
    _anchorChildren.add(child);
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  void _removeChild(_MenuAnchorState child) {
    assert(_isRoot || _debugMenuInfo('Removed root child: $child'));
    assert(_anchorChildren.contains(child));
    _anchorChildren.remove(child);
    assert(_debugMenuInfo('Tree:\n${widget.toStringDeep()}'));
  }

  _MenuAnchorState? get _nextSibling {
    final int index = _parent!._anchorChildren.indexOf(this);
    assert(index != -1, 'Unable to find this widget $this in parent $_parent');
    if (index < _parent!._anchorChildren.length - 1) {
      return _parent!._anchorChildren[index + 1];
    }
    return null;
  }

  _MenuAnchorState? get _previousSibling {
    final int index = _parent!._anchorChildren.indexOf(this);
    assert(index != -1, 'Unable to find this widget $this in parent $_parent');
    if (index > 0) {
      return _parent!._anchorChildren[index - 1];
    }
    return null;
  }

  _MenuAnchorState get _root {
    _MenuAnchorState anchor = this;
    while (anchor._parent != null) {
      anchor = anchor._parent!;
    }
    return anchor;
  }

  _MenuAnchorState get _topLevel {
    _MenuAnchorState handle = this;
    while (handle._parent!._isTopLevel) {
      handle = handle._parent!;
    }
    return handle;
  }

  void _childChangedOpenState(bool value) {
    if (_childIsOpen != value) {
      _parent?._childChangedOpenState(_childIsOpen || _isOpen);
      if (mounted) {
        setState(() {
          _childIsOpen = value;
        });
      }
    }
  }

  void _focusButton() {
    if (widget.childFocusNode == null) {
      return;
    }
    assert(_debugMenuInfo('Requesting focus for ${widget.childFocusNode}'));
    widget.childFocusNode!.requestFocus();
  }

  void _handleScroll() {
    // If an ancestor scrolls, and we're a top level or root anchor, then close
    // the menus. Don't just close it on *any* scroll, since we want to be able
    // to scroll menus themselves if they're too big for the view.
    if (_isTopLevel || _isRoot) {
      _root._close();
    }
  }

  /// Open the menu, optionally at a position relative to the [MenuAnchor].
  ///
  /// Call this when the menu should be shown to the user.
  ///
  /// The optional `position` argument will specify the location of the menu in
  /// the local coordinates of the [MenuAnchor], ignoring any
  /// [MenuStyle.alignment] and/or [MenuAnchor.alignmentOffset] that were
  /// specified.
  void _open({Offset? position}) {
    assert(_menuController._anchor == this);
    if (_isOpen && position == null) {
      assert(_debugMenuInfo("Not opening $this because it's already open"));
      return;
    }
    if (_isOpen && position != null) {
      // The menu is already open, but we need to move to another location, so
      // close it first.
      _close();
    }
    assert(_debugMenuInfo(
        'Opening ${this} at ${position ?? Offset.zero} with alignment offset ${widget.alignmentOffset ?? Offset.zero}'));
    _parent?._closeChildren(); // Close all siblings.
    assert(_overlayEntry == null);

    final BuildContext outerContext = context;
    setState(() {
      _parent?._childChangedOpenState(true);
      _overlayEntry = OverlayEntry(
        builder: (BuildContext context) {
          final OverlayState overlay = Overlay.of(outerContext);
          return Stack(
            children: [
              if (widget.closeOnOutsideClick)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _close();
                      _closeChildren();
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              Positioned.directional(
                textDirection: Directionality.of(outerContext),
                top: 0,
                start: 0,
                child: Directionality(
                  textDirection: Directionality.of(outerContext),
                  child: InheritedTheme.captureAll(
                    // Copy all the themes from the supplied outer context to the
                    // overlay.
                    outerContext,
                    _MenuAnchorMarker(
                      anchorKey: _anchorKey,
                      anchor: this,
                      child: _Submenu(
                        anchor: this,
                        menuStyle: widget.style,
                        alignmentOffset: widget.alignmentOffset ?? Offset.zero,
                        menuPosition: position,
                        clipBehavior: widget.clipBehavior,
                        menuChildren: widget.menuChildren,
                      ),
                    ),
                    to: overlay.context,
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
    widget.onOpen?.call();
  }

  /// Close the menu.
  ///
  /// Call this when the menu should be closed. Has no effect if the menu is
  /// already closed.
  void _close({bool inDispose = false}) {
    assert(_debugMenuInfo('Closing $this'));
    if (!_isOpen) {
      return;
    }
    _closeChildren(inDispose: inDispose);
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!inDispose && mounted) {
      setState(() {
        // Notify that _isOpen may have changed state, but only if not currently
        // disposing or unmounted.
        _parent?._childChangedOpenState(false);
      });
    }
    widget.onClose?.call();
  }

  void _closeChildren({bool inDispose = false}) {
    assert(_debugMenuInfo(
        'Closing children of ${this}${inDispose ? ' (dispose)' : ''}'));
    for (final _MenuAnchorState child
        in List<_MenuAnchorState>.from(_anchorChildren)) {
      child._close(inDispose: inDispose);
    }
  }

  // Returns the active anchor in the given context, if any, and creates a
  // dependency relationship that will rebuild the context when the node
  // changes.
  static _MenuAnchorState? _maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_MenuAnchorMarker>()
        ?.anchor;
  }
}

/// A controller to manage a menu created by a [CustomMenuBar] or [MenuAnchor].
///
/// A [CustomMenuController] is used to control and interrogate a menu after it has
/// been created, with methods such as [open] and [close], and state accessors
/// like [isOpen].
///
/// See also:
///
/// * [MenuAnchor], a widget that defines a region that has submenu.
/// * [CustomMenuBar], a widget that creates a menu bar, that can take an optional
///   [CustomMenuController].
/// * [CustomSubmenuButton], a widget that has a button that manages a submenu.
class CustomMenuController {
  /// The anchor that this controller controls.
  ///
  /// This is set automatically when a [CustomMenuController] is given to the anchor
  /// it controls.
  _MenuAnchorState? _anchor;

  /// Whether or not the associated menu is currently open.
  bool get isOpen {
    assert(_anchor != null);
    return _anchor!._isOpen;
  }

  /// Close the menu that this menu controller is associated with.
  ///
  /// Associating with a menu is done by passing a [CustomMenuController] to a
  /// [MenuAnchor]. A [CustomMenuController] is also be received by the
  /// [MenuAnchor.builder] when invoked.
  ///
  /// If the menu's anchor point (either a [CustomMenuBar] or a [MenuAnchor]) is
  /// scrolled by an ancestor, or the view changes size, then any open menu will
  /// automatically close.
  void close() {
    assert(_anchor != null);
    _anchor!._close();
  }

  /// Opens the menu that this menu controller is associated with.
  ///
  /// If `position` is given, then the menu will open at the position given, in
  /// the coordinate space of the [MenuAnchor] this controller is attached to.
  ///
  /// If given, the `position` will override the [MenuAnchor.alignmentOffset]
  /// given to the [MenuAnchor].
  ///
  /// If the menu's anchor point (either a [CustomMenuBar] or a [MenuAnchor]) is
  /// scrolled by an ancestor, or the view changes size, then any open menu will
  /// automatically close.
  void open({Offset? position}) {
    assert(_anchor != null);
    _anchor!._open(position: position);
  }

  // ignore: use_setters_to_change_properties
  void _attach(_MenuAnchorState anchor) {
    _anchor = anchor;
  }

  void _detach(_MenuAnchorState anchor) {
    if (_anchor == anchor) {
      _anchor = null;
    }
  }
}

/// A menu bar that manages cascading child menus.
///
/// This is a Material Design menu bar that typically resides above the main
/// body of an application (but can go anywhere) that defines a menu system for
/// invoking callbacks in response to user selection of a menu item.
///
/// The menus can be opened with a click or tap. Once a menu is opened, it can
/// be navigated by using the arrow and tab keys or via mouse hover. Selecting a
/// menu item can be done by pressing enter, or by clicking or tapping on the
/// menu item. Clicking or tapping on any part of the user interface that isn't
/// part of the menu system controlled by the same controller will cause all of
/// the menus controlled by that controller to close, as will pressing the
/// escape key.
///
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open, and
/// hovering over other items will close the previous menu and open the newly
/// hovered one. When those open/close transitions occur, [CustomSubmenuButton.onOpen],
/// and [CustomSubmenuButton.onClose] are called on the corresponding [CustomSubmenuButton] child
/// of the menu bar.
///
/// {@template flutter.material.menu_bar.shortcuts_note}
/// Menus using [CustomMenuItemButton] can have a [SingleActivator] or
/// [CharacterActivator] assigned to them as their [CustomMenuItemButton.shortcut],
/// which will display an appropriate shortcut hint. Even though the shortcut
/// labels are displayed in the menu, shortcuts are not automatically handled.
/// They must be available in whatever context they are appropriate, and handled
/// via another mechanism.
///
/// If shortcuts should be generally enabled, but are not easily defined in a
/// context surrounding the menu bar, consider registering them with a
/// [ShortcutRegistry] (one is already included in the [WidgetsApp], and thus
/// also [MaterialApp] and [CupertinoApp]), as shown in the example below. To be
/// sure that selecting a menu item and triggering the shortcut do the same
/// thing, it is recommended that they call the same callback.
///
/// {@tool dartpad}
/// This example shows a [CustomMenuBar] that contains a single top level menu,
/// containing three items: "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value, and the
/// shortcuts are registered globally with the [ShortcutRegistry].
///
/// ** See code in examples/api/lib/material/menu_anchor/menu_bar.0.dart **
/// {@end-tool}
/// {@endtemplate}
///
/// See also:
///
/// * [MenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [CustomSubmenuButton], a menu item which manages a submenu.
/// * [CustomMenuItemButton], a leaf menu item which displays the label, an optional
///   shortcut label, and optional leading and trailing icons.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
class CustomMenuBar extends StatelessWidget {
  /// Creates a const [CustomMenuBar].
  ///
  /// The [children] argument is required.
  const CustomMenuBar({
    super.key,
    this.style,
    this.clipBehavior = Clip.none,
    this.controller,
    required this.children,
  });

  /// The [MenuStyle] that defines the visual attributes of the menu bar.
  ///
  /// Colors and sizing of the menus is controllable via the [MenuStyle].
  ///
  /// Defaults to the ambient [MenuThemeData.style].
  final CustomMenuStyle? style;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The [CustomMenuController] to use for this menu bar.
  final CustomMenuController? controller;

  /// The list of menu items that are the top level children of the [CustomMenuBar].
  ///
  /// A Widget in Flutter is immutable, so directly modifying the [children]
  /// with [List] APIs such as `someMenuBarWidget.menus.add(...)` will result in
  /// incorrect behaviors. Whenever the menus list is modified, a new list
  /// object must be provided.
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    return _MenuBarAnchor(
      controller: controller,
      clipBehavior: clipBehavior,
      style: style,
      menuChildren: children,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...children.map<DiagnosticsNode>(
        (Widget item) => item.toDiagnosticsNode(),
      ),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomMenuStyle?>('style', style,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior,
        defaultValue: null));
  }
}

/// A button for use in a [CustomMenuBar], in a menu created with [MenuAnchor], or on
/// its own, that can be activated by click or keyboard navigation.
///
/// This widget represents a leaf entry in a menu hierarchy that is typically
/// part of a [CustomMenuBar], but may be used independently, or as part of a menu
/// created with a [MenuAnchor].
///
/// {@macro flutter.material.menu_bar.shortcuts_note}
///
/// See also:
///
/// * [CustomMenuBar], a class that creates a top level menu bar in a Material Design
///   style.
/// * [MenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [CustomSubmenuButton], a menu item similar to this one which manages a submenu.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
class CustomMenuItemButton extends StatefulWidget {
  /// Creates a const [CustomMenuItemButton].
  ///
  /// The [child] attribute is required.
  const CustomMenuItemButton({
    super.key,
    this.onPressed,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.shortcut,
    this.style,
    this.statesController,
    this.clipBehavior = Clip.none,
    this.leadingIcon,
    this.trailingIcon,
    required this.child,
  });

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback is null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onPressed;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered button
  /// area and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The optional shortcut that selects this [CustomMenuItemButton].
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final MenuSerializableShortcut? shortcut;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [WidgetStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [WidgetStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// {@macro flutter.material.inkwell.statesController}
  final WidgetStatesController? statesController;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// An optional icon to display before the [child] label.
  final Widget? leadingIcon;

  /// An optional icon to display after the [child] label.
  final Widget? trailingIcon;

  /// The widget displayed in the center of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Whether the button is enabled or disabled.
  ///
  /// To enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  State<CustomMenuItemButton> createState() => _CustomMenuItemButtonState();

  /// Defines the button's default appearance.
  ///
  /// {@macro flutter.material.text_button.default_style_of}
  ///
  /// {@macro flutter.material.text_button.material3_defaults}
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return CustomMenuButtonTheme.of(context).style;
  }

  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    TextStyle? textStyle,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      textStyle: textStyle,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(
        DiagnosticsProperty<ButtonStyle?>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<MenuSerializableShortcut?>(
        'shortcut', shortcut,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('leadingIcon', leadingIcon,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('trailingIcon', trailingIcon,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode,
        defaultValue: null));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior,
        defaultValue: Clip.none));
    properties.add(DiagnosticsProperty<WidgetStatesController?>(
        'statesController', statesController,
        defaultValue: null));
  }
}

class _CustomMenuItemButtonState extends State<CustomMenuItemButton> {
  // If a focus node isn't given to the widget, then we have to manage our own.
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _createInternalFocusNodeIfNeeded();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomMenuItemButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _createInternalFocusNodeIfNeeded();
      _focusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Since we don't want to use the theme style or default style from the
    // TextButton, we merge the styles, merging them in the right order when
    // each type of style exists. Each "*StyleOf" function is only called once.
    final ButtonStyle mergedStyle = widget.style?.merge(widget
            .themeStyleOf(context)
            ?.merge(widget.defaultStyleOf(context))) ??
        widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
        widget.defaultStyleOf(context);

    return TextButton(
      onPressed: widget.enabled ? _handleSelect : null,
      onHover: widget.enabled ? _handleHover : null,
      onFocusChange: widget.enabled ? widget.onFocusChange : null,
      focusNode: _focusNode,
      style: mergedStyle,
      statesController: widget.statesController,
      clipBehavior: widget.clipBehavior,
      child: _MenuItemLabel(
        leadingIcon: widget.leadingIcon,
        shortcut: widget.shortcut,
        trailingIcon: widget.trailingIcon,
        hasSubmenu: false,
        child: widget.child!,
      ),
    );
  }

  void _handleFocusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      // Close any child menus of this button's menu.
      _MenuAnchorState._maybeOf(context)?._closeChildren();
    }
  }

  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);
    if (hovering) {
      assert(_debugMenuInfo('Requesting focus for $_focusNode from hover'));
      _focusNode.requestFocus();
    }
  }

  void _handleSelect() {
    assert(_debugMenuInfo('Selected ${widget.child} menu'));
    widget.onPressed?.call();
    _MenuAnchorState._maybeOf(context)?._root._close();
  }

  void _createInternalFocusNodeIfNeeded() {
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel =
              '$CustomMenuItemButton(${widget.child})';
        }
        return true;
      }());
    }
  }
}

/// A menu button that displays a cascading menu.
///
/// It can be used as part of a [CustomMenuBar], or as a standalone widget.
///
/// This widget represents a menu item that has a submenu. Like the leaf
/// [CustomMenuItemButton], it shows a label with an optional leading or trailing
/// icon, but additionally shows an arrow icon showing that it has a submenu.
///
/// By default the submenu will appear to the side of the controlling button.
/// The alignment and offset of the submenu can be controlled by setting
/// [MenuStyle.alignment] on the [style] and the [alignmentOffset] argument,
/// respectively.
///
/// When activated (by being clicked, through keyboard navigation, or via
/// hovering with a mouse), it will open a submenu containing the
/// [menuChildren].
///
/// If [menuChildren] is empty, then this menu item will appear disabled.
///
/// See also:
///
/// * [CustomMenuItemButton], a widget that represents a leaf menu item that does not
///   host a submenu.
/// * [CustomMenuBar], a widget that renders menu items in a row in a Material Design
///   style.
/// * [MenuAnchor], a widget that creates a region with a submenu and shows it
///   when requested.
/// * [PlatformMenuBar], a widget that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs instead of Flutter.
class CustomSubmenuButton extends StatefulWidget {
  /// Creates a const [CustomSubmenuButton].
  ///
  /// The [child] and [menuChildren] attributes are required.
  const CustomSubmenuButton({
    super.key,
    this.onHover,
    this.onFocusChange,
    this.onOpen,
    this.onClose,
    this.style,
    this.menuStyle,
    this.alignmentOffset,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.statesController,
    this.leadingIcon,
    this.trailingIcon,
    this.closeOnOutsideClick = false,
    required this.menuChildren,
    required this.child,
  });

  final bool closeOnOutsideClick;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered this
  /// part of the button and false if a pointer has exited.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's [focusNode] gains focus, and false if it
  /// loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding properties in
  /// [themeStyleOf] and [defaultStyleOf]. [WidgetStateProperty]s that resolve
  /// to non-null values will similarly override the corresponding
  /// [WidgetStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// The [MenuStyle] of the menu specified by [menuChildren].
  ///
  /// Defaults to the value of [MenuThemeData.style] of the ambient [MenuTheme].
  final CustomMenuStyle? menuStyle;

  /// The offset of the menu relative to the alignment origin determined by
  /// [MenuStyle.alignment] on the [style] attribute.
  ///
  /// Use this for fine adjustments of the menu placement.
  ///
  /// Defaults to an offset that takes into account the padding of the menu so
  /// that the top starting corner of the first menu item is aligned with the
  /// top of the [MenuAnchor] region.
  final Offset? alignmentOffset;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.material.inkwell.statesController}
  final WidgetStatesController? statesController;

  /// An optional icon to display before the [child].
  final Widget? leadingIcon;

  /// An optional icon to display after the [child].
  final Widget? trailingIcon;

  /// The list of widgets that appear in the menu when it is opened.
  ///
  /// These can be any widget, but are typically either [CustomMenuItemButton] or
  /// [CustomSubmenuButton] widgets.
  ///
  /// If [menuChildren] is empty, then the button for this menu item will be
  /// disabled.
  final List<Widget> menuChildren;

  /// The widget displayed in the middle portion of this button.
  ///
  /// Typically this is the button's label, using a [Text] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  State<CustomSubmenuButton> createState() => _CustomSubmenuButtonState();

  /// Defines the button's default appearance.
  ///
  /// {@macro flutter.material.text_button.default_style_of}
  ///
  /// {@macro flutter.material.text_button.material3_defaults}
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest [MenuButtonTheme]
  /// ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return CustomMenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a [CustomSubmenuButton]'s
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] color is used to create a [WidgetStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. Use [backgroundColor] for the
  /// button's background fill color. Use [disabledForegroundColor] and
  /// [disabledBackgroundColor] to specify the button's disabled icon and fill
  /// color.
  ///
  /// All of the other parameters are either used directly or used to create a
  /// [WidgetStateProperty] with a single value for all states.
  ///
  /// All parameters default to null, by default this method returns a
  /// [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a
  /// [CustomSubmenuButton], as well as its overlay color, with all of the standard
  /// opacity adjustments for the pressed, focused, and hovered states, one
  /// could write:
  ///
  /// ```dart
  /// SubmenuButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: SubmenuButton.styleFrom(foregroundColor: Colors.green),
  ///   menuChildren: const <Widget>[ /* ... */ ],
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    TextStyle? textStyle,
    double? elevation,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    BorderSide? side,
    OutlinedBorder? shape,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      textStyle: textStyle,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menuChildren.map<DiagnosticsNode>((Widget child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon,
        defaultValue: null));
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<CustomMenuStyle>('menuStyle', menuStyle,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Offset>('alignmentOffset', alignmentOffset));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
  }
}

class _CustomSubmenuButtonState extends State<CustomSubmenuButton> {
  FocusNode? _internalFocusNode;
  bool _waitingToFocusMenu = false;
  final CustomMenuController _menuController = CustomMenuController();
  _MenuAnchorState? get _anchor => _MenuAnchorState._maybeOf(context);
  FocusNode get _buttonFocusNode => widget.focusNode ?? _internalFocusNode!;
  bool get _enabled => widget.menuChildren.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel =
              '$CustomSubmenuButton(${widget.child})';
        }
        return true;
      }());
    }
    _buttonFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomSubmenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChange);
      }
      if (widget.focusNode == null) {
        _internalFocusNode ??= FocusNode();
        assert(() {
          if (_internalFocusNode != null) {
            _internalFocusNode!.debugLabel =
                '$CustomSubmenuButton(${widget.child})';
          }
          return true;
        }());
      }
      _buttonFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Offset menuPaddingOffset;
    final EdgeInsets menuPadding = _computeMenuPadding(context);
    switch (_anchor?._root._orientation ?? Axis.vertical) {
      case Axis.horizontal:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            menuPaddingOffset =
                widget.alignmentOffset ?? Offset(-menuPadding.right, 0);
            break;
          case TextDirection.ltr:
            menuPaddingOffset =
                widget.alignmentOffset ?? Offset(-menuPadding.left, 0);
            break;
        }
        break;
      case Axis.vertical:
        menuPaddingOffset =
            widget.alignmentOffset ?? Offset(0, -menuPadding.top);
        break;
    }

    return MenuAnchor(
      controller: _menuController,
      childFocusNode: _buttonFocusNode,
      alignmentOffset: menuPaddingOffset,
      clipBehavior: widget.clipBehavior,
      onClose: widget.onClose,
      onOpen: widget.onOpen,
      style: widget.menuStyle,
      closeOnOutsideClick: widget.closeOnOutsideClick,
      builder: (BuildContext context, CustomMenuController controller,
          Widget? child) {
        // Since we don't want to use the theme style or default style from the
        // TextButton, we merge the styles, merging them in the right order when
        // each type of style exists. Each "*StyleOf" function is only called
        // once.
        final ButtonStyle mergedStyle = widget.style?.merge(widget
                .themeStyleOf(context)
                ?.merge(widget.defaultStyleOf(context))) ??
            widget
                .themeStyleOf(context)
                ?.merge(widget.defaultStyleOf(context)) ??
            widget.defaultStyleOf(context);

        void toggleShowMenu(BuildContext context) {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
            if (!_waitingToFocusMenu) {
              // Only schedule this if it's not already scheduled.
              SchedulerBinding.instance.addPostFrameCallback((Duration _) {
                // This has to happen in the next frame because the menu bar is
                // not focusable until the first menu is open.
                controller._anchor?._focusButton();
                _waitingToFocusMenu = false;
              });
              _waitingToFocusMenu = true;
            }
          }
        }

        // Called when the pointer is hovering over the menu button.
        void handleHover(bool hovering, BuildContext context) {
          widget.onHover?.call(hovering);
          // Don't open the root menu bar menus on hover unless something else
          // is already open. This means that the user has to first click to
          // open a menu on the menu bar before hovering allows them to traverse
          // it.
          if (controller._anchor!._root._orientation == Axis.horizontal &&
              !controller._anchor!._root._childIsOpen) {
            return;
          }

          if (hovering) {
            controller.open();
            controller._anchor!._focusButton();
          }
        }

        return TextButton(
          style: mergedStyle,
          focusNode: _buttonFocusNode,
          onHover: _enabled
              ? (bool hovering) => handleHover(hovering, context)
              : null,
          onPressed: _enabled ? () => toggleShowMenu(context) : null,
          child: _MenuItemLabel(
            leadingIcon: widget.leadingIcon,
            trailingIcon: widget.trailingIcon,
            hasSubmenu: true,
            showDecoration: (controller._anchor!._parent?._orientation ??
                    Axis.horizontal) ==
                Axis.vertical,
            child: child ?? const SizedBox(),
          ),
        );
      },
      menuChildren: widget.menuChildren,
      child: widget.child,
    );
  }

  EdgeInsets _computeMenuPadding(BuildContext context) {
    final CustomMenuStyle? themeStyle = CustomMenuTheme.of(context).style;
    final CustomMenuStyle defaultStyle = _MenuDefaultsM3(context);

    T? effectiveValue<T>(T? Function(CustomMenuStyle? style) getProperty) {
      return getProperty(widget.menuStyle) ??
          getProperty(themeStyle) ??
          getProperty(defaultStyle);
    }

    T? resolve<T>(
        WidgetStateProperty<T>? Function(CustomMenuStyle? style) getProperty) {
      return effectiveValue(
        (CustomMenuStyle? style) {
          return getProperty(style)?.resolve(
              widget.statesController?.value ?? const <WidgetState>{});
        },
      );
    }

    return resolve<EdgeInsetsGeometry?>(
          (CustomMenuStyle? style) => style?.padding,
        )?.resolve(
          Directionality.of(context),
        ) ??
        EdgeInsets.zero;
  }

  void _handleFocusChange() {
    if (_buttonFocusNode.hasPrimaryFocus) {
      if (!_menuController.isOpen) {
        _menuController.open();
      }
    } else {
      if (!_menuController._anchor!._menuScopeNode.hasFocus &&
          _menuController.isOpen) {
        _menuController.close();
      }
    }
  }
}

/// An action that closes all the menus associated with the given
/// [CustomMenuController].
///
/// See also:
///
///  * [MenuAnchor], a widget that hosts a cascading submenu.
///  * [CustomMenuBar], a widget that defines a menu bar with cascading submenus.
class DismissMenuAction extends DismissAction {
  /// Creates a [DismissMenuAction].
  DismissMenuAction({required this.controller});

  /// The [CustomMenuController] associated with the menus that should be closed.
  final CustomMenuController controller;

  @override
  void invoke(DismissIntent intent) {
    assert(_debugMenuInfo('$runtimeType: Dismissing all open menus.'));
    controller._anchor!._root._close();
  }

  @override
  bool isEnabled(DismissIntent intent) {
    return controller.isOpen;
  }
}

/// A helper class used to generate shortcut labels for a
/// [MenuSerializableShortcut] (a subset of the subclasses of
/// [ShortcutActivator]).
///
/// This helper class is typically used by the [CustomMenuItemButton] and
/// [CustomSubmenuButton] classes to display a label for their assigned shortcuts.
///
/// Call [getShortcutLabel] with the [MenuSerializableShortcut] to get a label
/// for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class _LocalizedShortcutLabeler {
  _LocalizedShortcutLabeler._();

  static _LocalizedShortcutLabeler? _instance;

  static final Map<LogicalKeyboardKey, String> _shortcutGraphicEquivalents =
      <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowLeft: '←',
    LogicalKeyboardKey.arrowRight: '→',
    LogicalKeyboardKey.arrowUp: '↑',
    LogicalKeyboardKey.arrowDown: '↓',
    LogicalKeyboardKey.enter: '↵',
    LogicalKeyboardKey.shift: '⇧',
    LogicalKeyboardKey.shiftLeft: '⇧',
    LogicalKeyboardKey.shiftRight: '⇧',
  };

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftRight,
  };

  /// Return the instance for this singleton.
  static _LocalizedShortcutLabeler get instance {
    return _instance ??= _LocalizedShortcutLabeler._();
  }

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final Map<MaterialLocalizations, Map<LogicalKeyboardKey, String>>
      _cachedShortcutKeys =
      <MaterialLocalizations, Map<LogicalKeyboardKey, String>>{};

  /// Returns the label to be shown to the user in the UI when a
  /// [MenuSerializableShortcut] is used as a keyboard shortcut.
  ///
  /// To keep the representation short, this will return graphical key
  /// representations when it can. For instance, the default
  /// [LogicalKeyboardKey.shift] will return '⇧', and the arrow keys will return
  /// arrows. When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], the key [LogicalKeyboardKey.meta] will show as '⌘',
  /// [LogicalKeyboardKey.control] will show as '˄', and
  /// [LogicalKeyboardKey.alt] will show as '⌥'.
  String getShortcutLabel(
      MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final ShortcutSerialization serialized = shortcut.serializeForMenu();
    if (serialized.trigger != null) {
      final List<String> modifiers = <String>[];
      final LogicalKeyboardKey trigger = serialized.trigger!;
      // These should be in this order, to match the LogicalKeySet version.
      if (serialized.alt!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.alt, localizations));
      }
      if (serialized.control!) {
        modifiers
            .add(_getModifierLabel(LogicalKeyboardKey.control, localizations));
      }
      if (serialized.meta!) {
        modifiers
            .add(_getModifierLabel(LogicalKeyboardKey.meta, localizations));
      }
      if (serialized.shift!) {
        modifiers
            .add(_getModifierLabel(LogicalKeyboardKey.shift, localizations));
      }
      String? shortcutTrigger;
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null &&
            logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          // If the trigger is a Unicode-character-producing key, then use the
          // character.
          shortcutTrigger =
              String.fromCharCode(logicalKeyId & LogicalKeyboardKey.valueMask)
                  .toUpperCase();
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty)
          shortcutTrigger,
      ].join(' ');
    } else if (serialized.character != null) {
      return serialized.character!;
    }
    throw UnimplementedError(
        'Shortcut labels for ShortcutActivators that do not implement '
        'MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or '
        'CharacterActivator) are not supported.');
  }

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String? _getLocalizedName(
      LogicalKeyboardKey key, MaterialLocalizations localizations) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.altGraph: localizations.keyboardKeyAltGraph,
      LogicalKeyboardKey.backspace: localizations.keyboardKeyBackspace,
      LogicalKeyboardKey.capsLock: localizations.keyboardKeyCapsLock,
      LogicalKeyboardKey.channelDown: localizations.keyboardKeyChannelDown,
      LogicalKeyboardKey.channelUp: localizations.keyboardKeyChannelUp,
      LogicalKeyboardKey.delete: localizations.keyboardKeyDelete,
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
      LogicalKeyboardKey.numLock: localizations.keyboardKeyNumLock,
      LogicalKeyboardKey.numpad1: localizations.keyboardKeyNumpad1,
      LogicalKeyboardKey.numpad2: localizations.keyboardKeyNumpad2,
      LogicalKeyboardKey.numpad3: localizations.keyboardKeyNumpad3,
      LogicalKeyboardKey.numpad4: localizations.keyboardKeyNumpad4,
      LogicalKeyboardKey.numpad5: localizations.keyboardKeyNumpad5,
      LogicalKeyboardKey.numpad6: localizations.keyboardKeyNumpad6,
      LogicalKeyboardKey.numpad7: localizations.keyboardKeyNumpad7,
      LogicalKeyboardKey.numpad8: localizations.keyboardKeyNumpad8,
      LogicalKeyboardKey.numpad9: localizations.keyboardKeyNumpad9,
      LogicalKeyboardKey.numpad0: localizations.keyboardKeyNumpad0,
      LogicalKeyboardKey.numpadAdd: localizations.keyboardKeyNumpadAdd,
      LogicalKeyboardKey.numpadComma: localizations.keyboardKeyNumpadComma,
      LogicalKeyboardKey.numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      LogicalKeyboardKey.numpadDivide: localizations.keyboardKeyNumpadDivide,
      LogicalKeyboardKey.numpadEnter: localizations.keyboardKeyNumpadEnter,
      LogicalKeyboardKey.numpadEqual: localizations.keyboardKeyNumpadEqual,
      LogicalKeyboardKey.numpadMultiply:
          localizations.keyboardKeyNumpadMultiply,
      LogicalKeyboardKey.numpadParenLeft:
          localizations.keyboardKeyNumpadParenLeft,
      LogicalKeyboardKey.numpadParenRight:
          localizations.keyboardKeyNumpadParenRight,
      LogicalKeyboardKey.numpadSubtract:
          localizations.keyboardKeyNumpadSubtract,
      LogicalKeyboardKey.pageDown: localizations.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp: localizations.keyboardKeyPageUp,
      LogicalKeyboardKey.power: localizations.keyboardKeyPower,
      LogicalKeyboardKey.powerOff: localizations.keyboardKeyPowerOff,
      LogicalKeyboardKey.printScreen: localizations.keyboardKeyPrintScreen,
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
  }

  String _getModifierLabel(
      LogicalKeyboardKey modifier, MaterialLocalizations localizations) {
    assert(_modifiers.contains(modifier),
        '${modifier.keyLabel} is not a modifier key');
    if (modifier == LogicalKeyboardKey.meta ||
        modifier == LogicalKeyboardKey.metaLeft ||
        modifier == LogicalKeyboardKey.metaRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return localizations.keyboardKeyMeta;
        case TargetPlatform.windows:
          return localizations.keyboardKeyMetaWindows;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌘';
      }
    }
    if (modifier == LogicalKeyboardKey.alt ||
        modifier == LogicalKeyboardKey.altLeft ||
        modifier == LogicalKeyboardKey.altRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyAlt;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌥';
      }
    }
    if (modifier == LogicalKeyboardKey.control ||
        modifier == LogicalKeyboardKey.controlLeft ||
        modifier == LogicalKeyboardKey.controlRight) {
      // '⎈' (a boat helm wheel, not an asterisk) is apparently the standard
      // icon for "control", but only seems to appear on the French Canadian
      // keyboard. A '✲' (an open center asterisk) appears on some Microsoft
      // keyboards. For all but macOS (which has standardized on "⌃", it seems),
      // we just return the local translation of "Ctrl".
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyControl;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌃';
      }
    }
    if (modifier == LogicalKeyboardKey.shift ||
        modifier == LogicalKeyboardKey.shiftLeft ||
        modifier == LogicalKeyboardKey.shiftRight) {
      return _shortcutGraphicEquivalents[LogicalKeyboardKey.shift]!;
    }
    throw ArgumentError('Keyboard key ${modifier.keyLabel} is not a modifier.');
  }
}

class _MenuAnchorMarker extends InheritedWidget {
  const _MenuAnchorMarker({
    required super.child,
    required this.anchorKey,
    required this.anchor,
  });

  final GlobalKey anchorKey;
  final _MenuAnchorState anchor;

  @override
  bool updateShouldNotify(_MenuAnchorMarker oldWidget) {
    return anchorKey != oldWidget.anchorKey || anchor != anchor;
  }
}

/// MenuBar-specific private specialization of [MenuAnchor] so that it can act
/// differently in regards to orientation, how open works, and what gets built.
class _MenuBarAnchor extends MenuAnchor {
  const _MenuBarAnchor({
    required super.menuChildren,
    super.controller,
    super.clipBehavior,
    super.style,
  });

  @override
  State<MenuAnchor> createState() => _MenuBarAnchorState();
}

class _MenuBarAnchorState extends _MenuAnchorState {
  @override
  bool get _isOpen {
    // If it's a bar, then it's "open" if any of its children are open.
    return _childIsOpen;
  }

  @override
  Axis get _orientation => Axis.horizontal;

  @override
  Widget _buildContents(BuildContext context) {
    return FocusScope(
      node: _menuScopeNode,
      skipTraversal: !_isOpen,
      canRequestFocus: _isOpen,
      child: ExcludeFocus(
        excluding: !_isOpen,
        child: Shortcuts(
          shortcuts: _kMenuTraversalShortcuts,
          child: Actions(
            actions: <Type, Action<Intent>>{
              DirectionalFocusIntent: _MenuDirectionalFocusAction(),
              DismissIntent: DismissMenuAction(controller: _menuController),
            },
            child: Builder(builder: (BuildContext context) {
              return _MenuPanel(
                menuStyle: widget.style,
                clipBehavior: widget.clipBehavior,
                orientation: Axis.horizontal,
                children: widget.menuChildren,
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void _open({Offset? position}) {
    assert(_menuController._anchor == this);
    // Menu bars can't be opened, because they're already always open.
    return;
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction();

  @override
  void invoke(DirectionalFocusIntent intent) {
    assert(_debugMenuInfo('_MenuDirectionalFocusAction invoked with $intent'));
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      super.invoke(intent);
      return;
    }
    final _MenuAnchorState? anchor = _MenuAnchorState._maybeOf(context);
    if (anchor == null || !anchor._root._isOpen) {
      super.invoke(intent);
      return;
    }
    final bool buttonIsFocused =
        anchor.widget.childFocusNode?.hasPrimaryFocus ?? false;
    Axis orientation;
    if (buttonIsFocused) {
      orientation = anchor._parent!._orientation;
    } else {
      orientation = anchor._orientation;
    }
    final bool firstItemIsFocused =
        anchor._firstItemFocusNode?.hasPrimaryFocus ?? false;
    assert(_debugMenuInfo(
        'In _MenuDirectionalFocusAction, current node is ${anchor.widget.childFocusNode?.debugLabel}, '
        'button is${buttonIsFocused ? '' : ' not'} focused. Assuming ${orientation.name} orientation.'));

    switch (intent.direction) {
      case TraversalDirection.up:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToParent(anchor)) {
              return;
            }
            break;
          case Axis.vertical:
            if (firstItemIsFocused) {
              if (_moveToParent(anchor)) {
                return;
              }
            }
            if (_moveToPrevious(anchor)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.down:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToSubmenu(anchor)) {
              return;
            }
            break;
          case Axis.vertical:
            if (_moveToNext(anchor)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.left:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToNext(anchor)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToPrevious(anchor)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(anchor)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(anchor)) {
                    return;
                  }
                }
                break;
              case TextDirection.ltr:
                switch (anchor._parent!._orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(anchor)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (buttonIsFocused) {
                      if (_moveToPreviousTopLevel(anchor)) {
                        return;
                      }
                    } else {
                      if (_moveToParent(anchor)) {
                        return;
                      }
                    }
                    break;
                }
                break;
            }
            break;
        }
        break;
      case TraversalDirection.right:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToPrevious(anchor)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToNext(anchor)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                switch (anchor._parent!._orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(anchor)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (_moveToParent(anchor)) {
                      return;
                    }
                    break;
                }
                break;
              case TextDirection.ltr:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(anchor)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(anchor)) {
                    return;
                  }
                }
                break;
            }
            break;
        }
        break;
    }
    super.invoke(intent);
  }

  bool _moveToNext(_MenuAnchorState currentMenu) {
    assert(_debugMenuInfo('Moving focus to next item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    if (currentMenu.widget.childFocusNode != null) {
      final FocusTraversalPolicy? policy =
          FocusTraversalGroup.maybeOf(primaryFocus!.context!);
      policy?.invalidateScopeData(
          currentMenu.widget.childFocusNode!.nearestScope!);
    }
    return false;
  }

  bool _moveToNextTopLevel(_MenuAnchorState currentMenu) {
    final _MenuAnchorState? sibling = currentMenu._topLevel._nextSibling;
    if (sibling == null) {
      // Wrap around to the first top level.
      currentMenu._topLevel._parent!._anchorChildren.first._focusButton();
    } else {
      sibling._focusButton();
    }
    return true;
  }

  bool _moveToParent(_MenuAnchorState currentMenu) {
    assert(_debugMenuInfo('Moving focus to parent menu button'));
    if (!(currentMenu.widget.childFocusNode?.hasPrimaryFocus ?? true)) {
      currentMenu._focusButton();
    }
    return true;
  }

  bool _moveToPrevious(_MenuAnchorState currentMenu) {
    assert(_debugMenuInfo('Moving focus to previous item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    if (currentMenu.widget.childFocusNode != null) {
      final FocusTraversalPolicy? policy =
          FocusTraversalGroup.maybeOf(primaryFocus!.context!);
      policy?.invalidateScopeData(
          currentMenu.widget.childFocusNode!.nearestScope!);
    }
    return false;
  }

  bool _moveToPreviousTopLevel(_MenuAnchorState currentMenu) {
    final _MenuAnchorState? sibling = currentMenu._topLevel._previousSibling;
    if (sibling == null) {
      // Already on the first one, wrap around to the last one.
      currentMenu._topLevel._parent!._anchorChildren.last._focusButton();
    } else {
      sibling._focusButton();
    }
    return true;
  }

  bool _moveToSubmenu(_MenuAnchorState currentMenu) {
    assert(_debugMenuInfo('Opening submenu'));
    if (!currentMenu._isOpen) {
      // If no submenu is open, then an arrow opens the submenu.
      currentMenu._open();
      return true;
    } else {
      final FocusNode? firstNode = currentMenu._firstItemFocusNode;
      if (firstNode != null && firstNode.nearestScope != firstNode) {
        // Don't request focus if the "first" found node is a focus scope, since
        // that means that nothing else in the submenu is focusable.
        firstNode.requestFocus();
      }
      return true;
    }
  }
}

/// A label widget that is used as the label for a [CustomMenuItemButton] or
/// [CustomSubmenuButton].
///
/// It not only shows the [CustomSubmenuButton.child] or [CustomMenuItemButton.child], but if
/// there is a shortcut associated with the [CustomMenuItemButton], it will display a
/// mnemonic for the shortcut. For [CustomSubmenuButton]s, it will display a visual
/// indicator that there is a submenu.
class _MenuItemLabel extends StatelessWidget {
  /// Creates a const [_MenuItemLabel].
  ///
  /// The [child] and [hasSubmenu] arguments are required.
  const _MenuItemLabel({
    required this.hasSubmenu,
    this.showDecoration = true,
    this.leadingIcon,
    this.trailingIcon,
    this.shortcut,
    required this.child,
  });

  /// Whether or not this menu has a submenu.
  ///
  /// Determines whether the submenu arrow is shown or not.
  final bool hasSubmenu;

  /// Whether or not this item should show decorations like shortcut labels or
  /// submenu arrows. Items in a [CustomMenuBar] don't show these decorations when
  /// they are laid out horizontally.
  final bool showDecoration;

  /// The optional icon that comes before the [child].
  final Widget? leadingIcon;

  /// The optional icon that comes after the [child].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// The required label child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final VisualDensity density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leadingIcon != null) leadingIcon!,
            Padding(
              padding: leadingIcon != null
                  ? EdgeInsetsDirectional.only(start: horizontalPadding)
                  : EdgeInsets.zero,
              child: child,
            ),
            if (trailingIcon != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                child: trailingIcon,
              ),
          ],
        ),
        if (showDecoration && (shortcut != null || hasSubmenu))
          SizedBox(width: horizontalPadding),
        if (showDecoration && shortcut != null)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: Text(
              _LocalizedShortcutLabeler.instance.getShortcutLabel(
                shortcut!,
                MaterialLocalizations.of(context),
              ),
            ),
          ),
        if (showDecoration && hasSubmenu)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: const Icon(
              Icons.arrow_right, // Automatically switches with text direction.
              size: _kDefaultSubmenuIconSize,
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(DiagnosticsProperty<MenuSerializableShortcut>(
        'shortcut', shortcut,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('hasSubmenu', hasSubmenu));
    properties.add(DiagnosticsProperty<bool>('showDecoration', showDecoration));
  }
}

// Positions the menu in the view while trying to keep as much as possible
// visible in the view.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({
    required this.anchorRect,
    required this.textDirection,
    required this.alignment,
    required this.alignmentOffset,
    required this.menuPosition,
    required this.menuPadding,
    required this.avoidBounds,
    required this.orientation,
    required this.parentOrientation,
  });

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final Rect anchorRect;

  // Whether to prefer going to the left or to the right.
  final TextDirection textDirection;

  // The alignment to use when finding the ideal location for the menu.
  final AlignmentGeometry alignment;

  // The offset from the alignment position to find the ideal location for the
  // menu.
  final Offset alignmentOffset;

  // The position passed to the open method, if any.
  final Offset? menuPosition;

  // The padding on the inside of the menu, so it can be accounted for when
  // positioning.
  final EdgeInsetsGeometry menuPadding;

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

  // The orientation of this menu
  final Axis orientation;

  // The orientation of this menu's parent.
  final Axis parentOrientation;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus _kMenuViewPadding
    // pixels in each direction.
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuViewPadding),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.
    final Rect overlayRect = Offset.zero & size;
    double x;
    double y;
    if (menuPosition == null) {
      Offset desiredPosition =
          alignment.resolve(textDirection).withinRect(anchorRect);
      final Offset directionalOffset;
      if (alignment is AlignmentDirectional) {
        switch (textDirection) {
          case TextDirection.rtl:
            directionalOffset = Offset(-alignmentOffset.dx, alignmentOffset.dy);
            break;
          case TextDirection.ltr:
            directionalOffset = alignmentOffset;
            break;
        }
      } else {
        directionalOffset = alignmentOffset;
      }
      desiredPosition += directionalOffset;
      x = desiredPosition.dx;
      y = desiredPosition.dy;
      switch (textDirection) {
        case TextDirection.rtl:
          x -= childSize.width;
          break;
        case TextDirection.ltr:
          break;
      }
    } else {
      final Offset adjustedPosition = menuPosition! + anchorRect.topLeft;
      x = adjustedPosition.dx;
      y = adjustedPosition.dy;
    }

    final Iterable<Rect> subScreens =
        DisplayFeatureSubScreen.subScreensInBounds(overlayRect, avoidBounds);
    final Rect allowedRect = _closestScreen(subScreens, anchorRect.center);
    bool offLeftSide(double x) => x < allowedRect.left;
    bool offRightSide(double x) => x + childSize.width > allowedRect.right;
    bool offTop(double y) => y < allowedRect.top;
    bool offBottom(double y) => y + childSize.height > allowedRect.bottom;
    // Avoid going outside an area defined as the rectangle offset from the
    // edge of the screen by the button padding. If the menu is off of the screen,
    // move the menu to the other side of the button first, and then if it
    // doesn't fit there, then just move it over as much as needed to make it
    // fit.
    if (childSize.width >= allowedRect.width) {
      // It just doesn't fit, so put as much on the screen as possible.
      x = allowedRect.left;
    } else {
      if (offLeftSide(x)) {
        // If the parent is a different orientation than the current one, then
        // just push it over instead of trying the other side.
        if (parentOrientation != orientation) {
          x = allowedRect.left;
        } else {
          final double newX = anchorRect.right;
          if (!offRightSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.left;
          }
        }
      } else if (offRightSide(x)) {
        if (parentOrientation != orientation) {
          x = allowedRect.right - childSize.width;
        } else {
          final double newX = anchorRect.left - childSize.width;
          if (!offLeftSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.right - childSize.width;
          }
        }
      }
    }
    if (childSize.height >= allowedRect.height) {
      // Too tall to fit, fit as much on as possible.
      y = allowedRect.top;
    } else {
      if (offTop(y)) {
        final double newY = anchorRect.bottom;
        if (!offBottom(newY)) {
          y = newY;
        } else {
          y = allowedRect.top;
        }
      } else if (offBottom(y)) {
        final double newY = anchorRect.top - childSize.height;
        if (!offTop(newY)) {
          y = newY;
        } else {
          y = allowedRect.bottom - childSize.height;
        }
      }
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        textDirection != oldDelegate.textDirection ||
        alignment != oldDelegate.alignment ||
        alignmentOffset != oldDelegate.alignmentOffset ||
        menuPosition != oldDelegate.menuPosition ||
        orientation != oldDelegate.orientation ||
        parentOrientation != oldDelegate.parentOrientation ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance <
          (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }
}

/// A widget that manages a list of menu buttons in a menu.
///
/// It sizes itself to the widest/tallest item it contains, and then sizes all
/// the other entries to match.
class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    required this.menuStyle,
    this.clipBehavior = Clip.none,
    required this.orientation,
    required this.children,
  });

  /// The menu style that has all the attributes for this menu panel.
  final CustomMenuStyle? menuStyle;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The layout orientation of this panel.
  final Axis orientation;

  /// The list of widgets to use as children of this menu bar.
  ///
  /// These are the top level [CustomSubmenuButton]s.
  final List<Widget> children;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  @override
  Widget build(BuildContext context) {
    final CustomMenuStyle? themeStyle;
    final CustomMenuStyle defaultStyle;
    switch (widget.orientation) {
      case Axis.horizontal:
        themeStyle = CustomMenuTheme.of(context).style;
        defaultStyle = _MenuBarDefaultsM3(context);
        break;
      case Axis.vertical:
        themeStyle = CustomMenuTheme.of(context).style;
        defaultStyle = _MenuDefaultsM3(context);
        break;
    }
    final CustomMenuStyle? widgetStyle = widget.menuStyle;

    T? effectiveValue<T>(T? Function(CustomMenuStyle? style) getProperty) {
      return getProperty(widgetStyle) ??
          getProperty(themeStyle) ??
          getProperty(defaultStyle);
    }

    T? resolve<T>(
        WidgetStateProperty<T>? Function(CustomMenuStyle? style) getProperty) {
      return effectiveValue(
        (CustomMenuStyle? style) {
          return getProperty(style)?.resolve(<WidgetState>{});
        },
      );
    }

    final Color? backgroundColor = theme.background1;
    final Color? shadowColor =
        resolve<Color?>((CustomMenuStyle? style) => style?.shadowColor);
    final Color? surfaceTintColor =
        resolve<Color?>((CustomMenuStyle? style) => style?.surfaceTintColor);
    final double elevation =
        resolve<double?>((CustomMenuStyle? style) => style?.elevation) ?? 0;
    final Size? minimumSize =
        resolve<Size?>((CustomMenuStyle? style) => style?.minimumSize);
    final Size? fixedSize =
        resolve<Size?>((CustomMenuStyle? style) => style?.fixedSize);
    final Size? maximumSize =
        resolve<Size?>((CustomMenuStyle? style) => style?.maximumSize);
    final BorderSide? side =
        resolve<BorderSide?>((CustomMenuStyle? style) => style?.side);
    final OutlinedBorder shape =
        resolve<OutlinedBorder?>((CustomMenuStyle? style) => style?.shape)!
            .copyWith(side: side);
    final VisualDensity visualDensity =
        effectiveValue((CustomMenuStyle? style) => style?.visualDensity) ??
            VisualDensity.standard;
    final EdgeInsetsGeometry padding = resolve<EdgeInsetsGeometry?>(
            (CustomMenuStyle? style) => style?.padding) ??
        EdgeInsets.zero;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;
    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.fromLTRB(dx, dy, dx, dy))
        .clamp(EdgeInsets.zero,
            EdgeInsetsGeometry.infinity); // ignore_clamp_double_lint

    BoxConstraints effectiveConstraints = visualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: minimumSize?.width ?? 0,
        minHeight: minimumSize?.height ?? 0,
        maxWidth: maximumSize?.width ?? double.infinity,
        maxHeight: maximumSize?.height ?? double.infinity,
      ),
    );
    if (fixedSize != null) {
      final Size size = effectiveConstraints.constrain(fixedSize);
      if (size.width.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minWidth: size.width,
          maxWidth: size.width,
        );
      }
      if (size.height.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minHeight: size.height,
          maxHeight: size.height,
        );
      }
    }
    return ConstrainedBox(
      constraints: effectiveConstraints,
      child: UnconstrainedBox(
        constrainedAxis: widget.orientation,
        clipBehavior: Clip.hardEdge,
        alignment: AlignmentDirectional.centerStart,
        child: _intrinsicCrossSize(
          child: Material(
            elevation: elevation,
            shape: shape,
            color: backgroundColor,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            type: backgroundColor == null
                ? MaterialType.transparency
                : MaterialType.canvas,
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: resolvedPadding,
              child: SingleChildScrollView(
                scrollDirection: widget.orientation,
                child: Flex(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: Directionality.of(context),
                  direction: widget.orientation,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intrinsicCrossSize({required Widget child}) {
    switch (widget.orientation) {
      case Axis.horizontal:
        return IntrinsicHeight(child: child);
      case Axis.vertical:
        return IntrinsicWidth(child: child);
    }
  }
}

// A widget that defines the menu drawn inside of the overlay entry.
class _Submenu extends StatelessWidget {
  const _Submenu({
    required this.anchor,
    required this.menuStyle,
    required this.menuPosition,
    required this.alignmentOffset,
    required this.clipBehavior,
    required this.menuChildren,
  });

  final _MenuAnchorState anchor;
  final CustomMenuStyle? menuStyle;
  final Offset? menuPosition;
  final Offset alignmentOffset;
  final Clip clipBehavior;
  final List<Widget> menuChildren;

  @override
  Widget build(BuildContext context) {
    // Use the text direction of the context where the button is.
    final TextDirection textDirection = Directionality.of(context);
    final CustomMenuStyle? themeStyle;
    final CustomMenuStyle defaultStyle;
    switch (anchor._parent?._orientation ?? Axis.horizontal) {
      case Axis.horizontal:
        themeStyle = CustomMenuTheme.of(context).style;
        defaultStyle = _MenuBarDefaultsM3(context);
        break;
      case Axis.vertical:
        themeStyle = CustomMenuTheme.of(context).style;
        defaultStyle = _MenuDefaultsM3(context);
        break;
    }
    T? effectiveValue<T>(T? Function(CustomMenuStyle? style) getProperty) {
      return getProperty(menuStyle) ??
          getProperty(themeStyle) ??
          getProperty(defaultStyle);
    }

    T? resolve<T>(
        WidgetStateProperty<T>? Function(CustomMenuStyle? style) getProperty) {
      return effectiveValue(
        (CustomMenuStyle? style) {
          return getProperty(style)?.resolve(<WidgetState>{});
        },
      );
    }

    final WidgetStateMouseCursor mouseCursor = _MouseCursor(
      (Set<WidgetState> states) => effectiveValue(
          (CustomMenuStyle? style) => style?.mouseCursor?.resolve(states)),
    );

    final VisualDensity visualDensity =
        effectiveValue((CustomMenuStyle? style) => style?.visualDensity) ??
            VisualDensity.standard;
    final AlignmentGeometry alignment =
        effectiveValue((CustomMenuStyle? style) => style?.alignment)!;
    final BuildContext anchorContext = anchor._anchorKey.currentContext!;
    final RenderBox overlay =
        Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
    final RenderBox anchorBox = anchorContext.findRenderObject()! as RenderBox;
    final Offset upperLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset bottomRight = anchorBox
        .localToGlobal(anchorBox.paintBounds.bottomRight, ancestor: overlay);
    final Rect anchorRect = Rect.fromPoints(upperLeft, bottomRight);
    final EdgeInsetsGeometry padding = resolve<EdgeInsetsGeometry?>(
            (CustomMenuStyle? style) => style?.padding) ??
        EdgeInsets.zero;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;
    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.fromLTRB(dx, dy, dx, dy))
        .clamp(EdgeInsets.zero,
            EdgeInsetsGeometry.infinity); // ignore_clamp_double_lint

    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: visualDensity,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(overlay.paintBounds.size),
        child: CustomSingleChildLayout(
          delegate: _MenuLayout(
            anchorRect: anchorRect,
            textDirection: textDirection,
            avoidBounds:
                DisplayFeatureSubScreen.avoidBounds(MediaQuery.of(context))
                    .toSet(),
            menuPadding: resolvedPadding,
            alignment: alignment,
            alignmentOffset: alignmentOffset,
            menuPosition: menuPosition,
            orientation: anchor._orientation,
            parentOrientation: anchor._parent?._orientation ?? Axis.horizontal,
          ),
          child: MouseRegion(
            cursor: mouseCursor,
            hitTestBehavior: HitTestBehavior.deferToChild,
            child: FocusScope(
              node: anchor._menuScopeNode,
              child: Actions(
                actions: <Type, Action<Intent>>{
                  DirectionalFocusIntent: _MenuDirectionalFocusAction(),
                  DismissIntent:
                      DismissMenuAction(controller: anchor._menuController),
                },
                child: Shortcuts(
                  shortcuts: _kMenuTraversalShortcuts,
                  child: Directionality(
                    // Copy the directionality from the button into the overlay.
                    textDirection: textDirection,
                    child: _MenuPanel(
                      menuStyle: menuStyle,
                      clipBehavior: clipBehavior,
                      orientation: anchor._orientation,
                      children: menuChildren,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the [WidgetStateMouseCursor] so that it can default to
/// [MouseCursor.uncontrolled] if none is set.
class _MouseCursor extends WidgetStateMouseCursor {
  const _MouseCursor(this.resolveCallback);

  final WidgetPropertyResolver<MouseCursor?> resolveCallback;

  @override
  MouseCursor resolve(Set<WidgetState> states) =>
      resolveCallback(states) ?? MouseCursor.uncontrolled;

  @override
  String get debugDescription => 'Menu_MouseCursor';
}

/// A debug print function, which should only be called within an assert, like
/// so:
///
///   assert(_debugMenuInfo('Debug Message'));
///
/// so that the call is entirely removed in release builds.
///
/// Enable debug printing by setting [_kDebugMenus] to true at the top of the
/// file.
bool _debugMenuInfo(String message, [Iterable<String>? details]) {
  assert(() {
    if (_kDebugMenus) {
      debugPrint('MENU: $message');
      if (details != null && details.isNotEmpty) {
        for (final String detail in details) {
          debugPrint('    $detail');
        }
      }
    }
    return true;
  }());
  // Return true so that it can be easily used inside of an assert.
  return true;
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuBarDefaultsM3 extends CustomMenuStyle {
  _MenuBarDefaultsM3(this.context)
      : super(
          elevation: const WidgetStatePropertyAll<double?>(4),
          shape:
              const WidgetStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.bottomStart,
        );
  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(2, 3)));

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?> get backgroundColor {
    return WidgetStatePropertyAll<Color?>(_colors.surface);
  }

  @override
  WidgetStateProperty<EdgeInsetsGeometry?>? get padding {
    return WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(
        horizontal: math.max(
          _kTopLevelMenuHorizontalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
        ),
      ),
    );
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuButtonDefaultsM3 extends ButtonStyle {
  _MenuButtonDefaultsM3(this.context)
      : super(
          animationDuration: kThemeChangeDuration,
          enableFeedback: true,
          alignment: AlignmentDirectional.centerStart,
        );
  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor {
    return ButtonStyleButton.allOrNull<Color>(Colors.transparent);
  }

  // No default shadow color

  // No default surface tint color

  @override
  WidgetStateProperty<double>? get elevation {
    return ButtonStyleButton.allOrNull<double>(0);
  }

  @override
  WidgetStateProperty<Color?>? get foregroundColor {
    return WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.primary;
      },
    );
  }

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize {
    return ButtonStyleButton.allOrNull<Size>(Size.infinite);
  }

  @override
  WidgetStateProperty<Size>? get minimumSize {
    return ButtonStyleButton.allOrNull<Size>(const Size(64, 40));
  }

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor {
    return WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      },
    );
  }

  @override
  WidgetStateProperty<Color?>? get overlayColor {
    return WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        return null;
      },
    );
  }

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding {
    return ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(
        _scaledPadding(context));
  }

  // No default side

  @override
  WidgetStateProperty<OutlinedBorder>? get shape {
    return ButtonStyleButton.allOrNull<OutlinedBorder>(
        const RoundedRectangleBorder());
  }

  @override
  InteractiveInkFeatureFactory? get splashFactory =>
      Theme.of(context).splashFactory;

  @override
  MaterialTapTargetSize? get tapTargetSize =>
      Theme.of(context).materialTapTargetSize;

  @override
  WidgetStateProperty<TextStyle?> get textStyle {
    return WidgetStatePropertyAll<TextStyle?>(
        Theme.of(context).textTheme.labelLarge);
  }

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  EdgeInsetsGeometry _scaledPadding(BuildContext context) {
    final double fontSize =
        Theme.of(context).textTheme.labelLarge?.fontSize ?? 14.0;
    final double fontSizeRatio =
        MediaQuery.textScalerOf(context).scale(fontSize) / 14.0;
    return ButtonStyleButton.scaledPadding(
      const EdgeInsets.all(8),
      const EdgeInsets.symmetric(horizontal: 8),
      const EdgeInsets.symmetric(horizontal: 4),
      fontSizeRatio,
    );
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuDefaultsM3 extends CustomMenuStyle {
  _MenuDefaultsM3(this.context)
      : super(
          elevation: const WidgetStatePropertyAll<double?>(4),
          shape:
              const WidgetStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.topEnd,
        );
  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(2, 3)));

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?> get backgroundColor {
    return WidgetStatePropertyAll<Color?>(_colors.surface);
  }

  @override
  WidgetStateProperty<EdgeInsetsGeometry?>? get padding {
    return WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(
        vertical: math.max(
          _kMenuVerticalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dy,
        ),
      ),
    );
  }
}
