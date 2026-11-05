// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dym_auth/dym_auth.dart' as _i7;
import 'package:dym_vendor/ui/navigation.dart' as _i8;
import 'package:dym_vendor/ui/views/home/home_view.dart' as _i4;
import 'package:dym_vendor/ui/views/sign_in/sign_in_view.dart' as _i3;
import 'package:dym_vendor/ui/views/startup/startup_view.dart' as _i2;
import 'package:dym_vendor/ui/views/startup/startup_viewmodel.dart' as _i6;
import 'package:flutter/material.dart' as _i5;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i9;

class Routes {
  static const startupView = '/';

  static const signInView = '/sign-in-view';

  static const homeView = '/home-view';

  static const all = <String>{startupView, signInView, homeView};
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(Routes.startupView, page: _i2.StartupView),
    _i1.RouteDef(Routes.signInView, page: _i3.SignInView),
    _i1.RouteDef(Routes.homeView, page: _i4.HomeView),
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
    _i3.SignInView: (data) {
      final args = data.getArgs<SignInViewArguments>(
        orElse: () => const SignInViewArguments(),
      );
      return _i5.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.SignInView(
          key: args.key,
          startWithProfile: args.startWithProfile,
        ),
        settings: data,
      );
    },
    _i4.HomeView: (data) {
      final args = data.getArgs<HomeViewArguments>(
        orElse: () => const HomeViewArguments(),
      );
      return _i5.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.HomeView(
          key: args.key,
          service: args.service,
          navigator: args.navigator,
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

class SignInViewArguments {
  const SignInViewArguments({this.key, this.startWithProfile = false});

  final _i5.Key? key;

  final bool startWithProfile;

  @override
  String toString() {
    return '{"key": "$key", "startWithProfile": "$startWithProfile"}';
  }

  @override
  bool operator ==(covariant SignInViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.startWithProfile == startWithProfile;
  }

  @override
  int get hashCode {
    return key.hashCode ^ startWithProfile.hashCode;
  }
}

class HomeViewArguments {
  const HomeViewArguments({this.key, this.service, this.navigator});

  final _i5.Key? key;

  final _i7.AuthService? service;

  final _i8.AppNavigator? navigator;

  @override
  String toString() {
    return '{"key": "$key", "service": "$service", "navigator": "$navigator"}';
  }

  @override
  bool operator ==(covariant HomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.service == service &&
        other.navigator == navigator;
  }

  @override
  int get hashCode {
    return key.hashCode ^ service.hashCode ^ navigator.hashCode;
  }
}

extension NavigatorStateExtension on _i9.NavigationService {
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

  Future<dynamic> navigateToSignInView({
    _i5.Key? key,
    bool startWithProfile = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.signInView,
      arguments: SignInViewArguments(
        key: key,
        startWithProfile: startWithProfile,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToHomeView({
    _i5.Key? key,
    _i7.AuthService? service,
    _i8.AppNavigator? navigator,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.homeView,
      arguments: HomeViewArguments(
        key: key,
        service: service,
        navigator: navigator,
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

  Future<dynamic> replaceWithSignInView({
    _i5.Key? key,
    bool startWithProfile = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.signInView,
      arguments: SignInViewArguments(
        key: key,
        startWithProfile: startWithProfile,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithHomeView({
    _i5.Key? key,
    _i7.AuthService? service,
    _i8.AppNavigator? navigator,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.homeView,
      arguments: HomeViewArguments(
        key: key,
        service: service,
        navigator: navigator,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }
}
