import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:history_app/blocs/all_cartoons/all_cartoons.dart';
import 'package:political_cartoon_repository/political_cartoon_repository.dart';

import 'filtered_cartoons.dart';

class FilteredCartoonsBloc
    extends Bloc<FilteredCartoonsEvent, FilteredCartoonsState> {
  FilteredCartoonsBloc({required AllCartoonsBloc allCartoonsBloc})
      : _allCartoonsBloc = allCartoonsBloc,
        super(FilteredCartoonsBloc.initialState(allCartoonsBloc)) {
    _allCartoonsSubscription = allCartoonsBloc.stream.listen((state) {
      if (state is AllCartoonsLoaded) {
        add(UpdateFilteredCartoons(state.cartoons));
      }
    });
  }

  final AllCartoonsBloc _allCartoonsBloc;
  late StreamSubscription _allCartoonsSubscription;

  static FilteredCartoonsState initialState(AllCartoonsBloc allCartoonsBloc) {
    if (allCartoonsBloc.state is AllCartoonsLoading) {
      return FilteredCartoonsLoading();
    } else if (allCartoonsBloc.state is AllCartoonsLoaded) {
      return FilteredCartoonsLoaded(
        (allCartoonsBloc.state as AllCartoonsLoaded).cartoons,
        Tag.all,
        ImageType.all
      );
    }
    return FilteredCartoonsFailed(
      (allCartoonsBloc.state as AllCartoonsFailed).errorMessage
    );
  }

  @override
  Stream<FilteredCartoonsState> mapEventToState(
      FilteredCartoonsEvent event) async* {
    if (event is UpdateFilter) {
      yield* _mapUpdateFilterToState(event);
    } else if (event is UpdateFilteredCartoons) {
      yield* _mapCartoonsUpdatedToState(event);
    }
  }

  Stream<FilteredCartoonsState> _mapUpdateFilterToState(
    UpdateFilter event,
  ) async* {
    final currentState = _allCartoonsBloc.state;
    if (currentState is AllCartoonsLoaded) {
      yield FilteredCartoonsLoaded(
        _mapCartoonsToFilteredCartoons(
          currentState.cartoons,
          event.filter,
          event.type
        ),
        event.filter,
        event.type,
      );
    }
  }

  Stream<FilteredCartoonsState> _mapCartoonsUpdatedToState(
    UpdateFilteredCartoons event,
  ) async* {

    final tagFilter = state is FilteredCartoonsLoaded
      ? (state as FilteredCartoonsLoaded).filter
      : Tag.all;

    final typeFilter = state is FilteredCartoonsLoaded
        ? (state as FilteredCartoonsLoaded).type
        : ImageType.all;

    if (_allCartoonsBloc.state is AllCartoonsLoaded) {
      yield FilteredCartoonsLoaded(
        _mapCartoonsToFilteredCartoons(
          (_allCartoonsBloc.state as AllCartoonsLoaded).cartoons,
          tagFilter,
          typeFilter,
        ),
        tagFilter,
        typeFilter,
      );
    }
  }

  List<PoliticalCartoon> _mapCartoonsToFilteredCartoons(
      List<PoliticalCartoon> cartoons, Tag filter, ImageType type) {

    var cartoonsFilteredByTags = cartoons.where((cartoon) {
      if (filter == Tag.all) {
        return true;
      } else {
        return cartoon.tags.contains(filter);
      }
    }).toList();

    return cartoonsFilteredByTags.where((cartoon) {
      if (type == ImageType.all) {
        return true;
      } else {
        return cartoon.type == type;
      }
    }).toList();

  }

  @override
  Future<void> close() {
    _allCartoonsSubscription.cancel();
    return super.close();
  }
}
