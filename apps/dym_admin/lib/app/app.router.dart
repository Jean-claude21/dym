// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dym_admin/ui/navigation.dart' as _i7;
import 'package:dym_admin/ui/views/home/admin_home_view.dart' as _i4;
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_view.dart' as _i3;
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart' as _i8;
import 'package:dym_admin/ui/views/startup/startup_view.dart' as _i2;
import 'package:dym_admin/ui/views/startup/startup_viewmodel.dart' as _i6;
import 'package:dym_auth/dym_auth.dart' as _i9;
import 'package:flutter/material.dart' as _i5;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i10;

class Routes {
  static const startupView = '/';

  static const adminSignInView = '/admin-sign-in-view';

  static const adminHomeView = '/admin-home-view';

  static const all = <String>{startupView, adminSignInView, adminHomeView};
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(Routes.startupView, page: _i2.StartupView),
    _i1.RouteDef(Routes.adminSignInView, page: _i3.AdminSignInView),
    _i1.RouteDef(Routes.adminHomeView, page: _i4.AdminHomeView),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i5.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.StartupView(
          key: args.key,
          viewModelFactory: args.viewModelFactory,
        ),
        settings: data,
      );
    },
    _i3.AdminSignInView: (data) {
      final args = data.getArgs<AdminSignInViewArguments>(
        orElse: () => const AdminSignInViewArguments(),
      );
      return _i5.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.AdminSignInView(
          key: args.key,
          notice: args.notice,
          viewModelFactory: args.viewModelFactory,
        ),
        settings: data,
      );
    },
    _i4.AdminHomeView: (data) {
      final args = data.getArgs<AdminHomeViewArguments>(
        orElse: () => const AdminHomeViewArguments(),
      );
      return _i5.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.AdminHomeView(
          key: args.key,
          service: args.service,
          navigator: args.navigator,
          inactivity: args.inactivity,
        ),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class StartupViewArguments {
  const StartupViewArguments({this.key, this.viewModelFactory});

  final _i5.Key? key;

  final _i6.StartupViewModel Function()? viewModelFactory;

  @override
  String toString() {
    return '{"key": "$key", "viewModelFactory": "$viewModelFactory"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.viewModelFactory == viewModelFactory;
  }

  @override
  int get hashCode {
    return key.hashCode ^ viewModelFactory.hashCode;
  }
}

class AdminSignInViewArguments {
  const AdminSignInViewArguments({
    this.key,
    this.notice,
    this.viewModelFactory,
  });

  final _i5.Key? key;

  final _i7.AdminNotice? notice;

  final _i8.AdminSignInViewModel Function()? viewModelFactory;

  @override
  String toString() {
    return '{"key": "$key", "notice": "$notice", "viewModelFactory": "$viewModelFactory"}';
  }

  @override
  bool operator ==(covariant AdminSignInViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.notice == notice &&
        other.viewModelFactory == viewModelFactory;
  }

  @override
  int get hashCode {
    return key.hashCode ^ notice.hashCode ^ viewModelFactory.hashCode;
  }
}

class AdminHomeViewArguments {
  const AdminHomeViewArguments({
    this.key,
    this.service,
    this.navigator,
    this.inactivity,
  });

  final _i5.Key? key;

  final _i9.AuthService? service;

  final _i7.AdminNavigator? navigator;

  final Duration? inactivity;

  @override
  String toString() {
    return '{"key": "$key", "service": "$service", "navigator": "$navigator", "inactivity": "$inactivity"}';
  }

  @override
  bool operator ==(covariant AdminHomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.service == service &&
        other.navigator == navigator &&
        other.inactivity == inactivity;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        service.hashCode ^
        navigator.hashCode ^
        inactivity.hashCode;
  }
}

extension NavigatorStateExtension on _i10.NavigationService {
  Future<dynamic> navigateToStartupView({
    _i5.Key? key,
    _i6.StartupViewModel Function()? viewModelFactory,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(
        key: key,
        viewModelFactory: viewModelFactory,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAdminSignInView({
    _i5.Key? key,
    _i7.AdminNotice? notice,
    _i8.AdminSignInViewModel Function()? viewModelFactory,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.adminSignInView,
      arguments: AdminSignInViewArguments(
        key: key,
        notice: notice,
        viewModelFactory: viewModelFactory,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAdminHomeView({
    _i5.Key? key,
    _i9.AuthService? service,
    _i7.AdminNavigator? navigator,
    Duration? inactivity,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.adminHomeView,
      arguments: AdminHomeViewArguments(
        key: key,
        service: service,
        navigator: navigator,
        inactivity: inactivity,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStartupView({
    _i5.Key? key,
    _i6.StartupViewModel Function()? viewModelFactory,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(
        key: key,
        viewModelFactory: viewModelFactory,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAdminSignInView({
    _i5.Key? key,
    _i7.AdminNotice? notice,
    _i8.AdminSignInViewModel Function()? viewModelFactory,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.adminSignInView,
      arguments: AdminSignInViewArguments(
        key: key,
        notice: notice,
        viewModelFactory: viewModelFactory,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAdminHomeView({
    _i5.Key? key,
    _i9.AuthService? service,
    _i7.AdminNavigator? navigator,
    Duration? inactivity,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.adminHomeView,
      arguments: AdminHomeViewArguments(
        key: key,
        service: service,
        navigator: navigator,
        inactivity: inactivity,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }
}
