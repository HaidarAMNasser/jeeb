import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_paginated_dropdown.dart';
import 'package:jeeb_app/features/country/presentation/bloc/country_bloc.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_app/features/city/presentation/bloc/city_bloc.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// A widget that combines Country and City dropdowns
/// Automatically handles the dependency: selecting a country loads cities
class CountryCityWidget extends StatefulWidget {
  final Function(CountryEntity?) onSelectCountry;
  final Function(CityEntity?) onSelectCity;
  final CountryEntity? selectedCountry;
  final CityEntity? selectedCity;
  final bool isRequired;
  final bool isReadOnly;

  const CountryCityWidget({
    super.key,
    required this.onSelectCountry,
    required this.onSelectCity,
    this.selectedCountry,
    this.selectedCity,
    this.isRequired = false,
    this.isReadOnly = false,
  });

  @override
  State<CountryCityWidget> createState() => _CountryCityWidgetState();
}

class _CountryCityWidgetState extends State<CountryCityWidget> {
  final Key _cityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Load countries on init
    context.read<CountryBloc>().add(const LoadCountries(withLoading: true));
  }

  @override
  void didUpdateWidget(CountryCityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If country changed, reset city
    if (widget.selectedCountry?.id != oldWidget.selectedCountry?.id) {
      setState(() {
        // Reset city when country changes
        widget.onSelectCity(null);
      });
      // Load cities for new country
      if (widget.selectedCountry != null) {
        context.read<CityBloc>().add(const ResetCities());
        context.read<CityBloc>().add(
              LoadCities(
                countryId: widget.selectedCountry!.id,
                withLoading: true,
              ),
            );
      } else {
        context.read<CityBloc>().add(const ResetCities());
      }
    }
  }

  void _onCountrySelected(CountryEntity? country) {
    widget.onSelectCountry(country);
    widget.onSelectCity(null); // Reset city when country changes

    if (country != null) {
      // Reset and load cities for selected country
      context.read<CityBloc>().add(const ResetCities());
      context.read<CityBloc>().add(
            LoadCities(
              countryId: country.id,
              withLoading: true,
            ),
          );
    } else {
      // Reset cities if no country selected
      context.read<CityBloc>().add(const ResetCities());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';

    return Column(
      children: [
        // Country Dropdown
        BlocBuilder<CountryBloc, CountryState>(
          builder: (context, state) {
            List<CountryEntity> countries = [];
            bool isLoading = false;
            bool isLoadingMore = false;
            bool hasMoreData = true;
            bool isError = false;
            String? errorMessage;

            if (state is CountryLoading) {
              isLoading = true;
            } else if (state is CountryError) {
              isError = true;
              errorMessage = state.message;
            } else if (state is CountryLoaded) {
              countries = state.countries;
              isLoadingMore = state.isLoadingMore;
              hasMoreData = !state.hasReachedMax;
            }

            return CustomPaginatedDropdown<CountryEntity>(
              title: AppTranslation.selectCountry,
              hintText: AppTranslation.selectCountry,
              items: countries,
              selectedItem: widget.selectedCountry,
              displayText: (country) => isRTL ? country.name.ar : country.name.en,
              onChanged: _onCountrySelected,
              onLoadMore: () {
                if (!isLoadingMore && hasMoreData) {
                  context.read<CountryBloc>().add(const LoadMoreCountries());
                }
              },
              isLoading: isLoading,
              isLoadingMore: isLoadingMore,
              hasMoreData: hasMoreData,
              isError: isError,
              errorMessage: errorMessage,
              isRequired: widget.isRequired,
              isReadOnly: widget.isReadOnly,
            );
          },
        ),
        SizedBox(height: AppHeight.s24),
        // City Dropdown
        BlocBuilder<CityBloc, CityState>(
          key: _cityKey,
          builder: (context, state) {
            List<CityEntity> cities = [];
            bool isLoading = false;
            bool isLoadingMore = false;
            bool hasMoreData = true;
            bool isError = false;
            String? errorMessage;

            if (state is CityLoading) {
              isLoading = true;
            } else if (state is CityError) {
              isError = true;
              errorMessage = state.message;
            } else if (state is CityLoaded) {
              cities = state.cities;
              isLoadingMore = state.isLoadingMore;
              hasMoreData = !state.hasReachedMax;
            }

            // Show message if no country selected
            if (widget.selectedCountry == null && state is! CityLoading) {
              return CustomPaginatedDropdown<CityEntity>(
                title: AppTranslation.selectCity,
                hintText: AppTranslation.pleaseSelectCountryFirst,
                items: [],
                selectedItem: null,
                displayText: (city) => isRTL ? city.name.ar : city.name.en,
                onChanged: widget.onSelectCity,
                isLoading: false,
                isLoadingMore: false,
                hasMoreData: false,
                isError: false,
                isRequired: widget.isRequired,
                isReadOnly: true, // Disable until country is selected
              );
            }

            return CustomPaginatedDropdown<CityEntity>(
              title: AppTranslation.selectCity,
              hintText: cities.isEmpty
                  ? AppTranslation.noCitiesAvailable
                  : AppTranslation.selectCity,
              items: cities,
              selectedItem: widget.selectedCity,
              displayText: (city) => isRTL ? city.name.ar : city.name.en,
              onChanged: widget.onSelectCity,
              onLoadMore: () {
                if (!isLoadingMore && hasMoreData && widget.selectedCountry != null) {
                  context.read<CityBloc>().add(const LoadMoreCities());
                }
              },
              isLoading: isLoading,
              isLoadingMore: isLoadingMore,
              hasMoreData: hasMoreData,
              isError: isError,
              errorMessage: errorMessage,
              isRequired: widget.isRequired,
              isReadOnly: widget.isReadOnly || widget.selectedCountry == null,
            );
          },
        ),
      ],
    );
  }
}

