import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_admin/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';
import 'package:jeeb_admin/core/common/utils/toast_util.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../../login/domain/entities/user_entity.dart';
import '../../../../lib/features/country/domain/entities/country_entity.dart';
import '../../../../lib/features/city/domain/entities/city_entity.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileBloc>().add(const GetProfile());
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleUpdateProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
        UpdateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          if (_firstNameController.text.isEmpty ||
              _firstNameController.text != state.user.firstName) {
            _firstNameController.text = state.user.firstName;
            _lastNameController.text = state.user.lastName;
            _phoneController.text = state.user.phone;
            _addressController.text = state.user.address ?? '';
          } else {
            customToast(msg: AppTranslation.profileUpdatedSuccess);
          }
        } else if (state is ProfileError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is ProfileLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(title: AppTranslation.profile),
            body:
                // Commented out BlocStateHandler for fake data display
                // BlocStateHandler<ProfileBloc, ProfileState>(
                //   bloc: context.read<ProfileBloc>(),
                //   isLoading: (state) => state is ProfileLoading,
                //   isError: (state) => state is ProfileError,
                //   getErrorMessage: (state) => (state as ProfileError).message,
                //   isSuccess: (state) => state is ProfileLoaded,
                //   successBuilder: (context, profileState) {
                //     final loadedState = profileState as ProfileLoaded;
                //     return SingleChildScrollView(
                //       padding: EdgeInsets.all(AppPadding.p24),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.stretch,
                //         children: [
                //           ProfileHeader(user: loadedState.user),
                //           SizedBox(height: AppHeight.s32),
                //           ProfileForm(
                //             formKey: _formKey,
                //             firstNameController: _firstNameController,
                //             lastNameController: _lastNameController,
                //             phoneController: _phoneController,
                //             addressController: _addressController,
                //             onUpdate: _handleUpdateProfile,
                //             isLoading: state is ProfileLoading,
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                // ),
                // Fake data for UI testing
                Builder(
                  builder: (context) {
                    final fakeUser = _generateFakeUser();
                    // Initialize controllers with fake data
                    _firstNameController.text = fakeUser.firstName;
                    _lastNameController.text = fakeUser.lastName;
                    _phoneController.text = fakeUser.phone;
                    _addressController.text = fakeUser.address ?? '';

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(AppPadding.p24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileHeader(user: fakeUser),
                          SizedBox(height: AppHeight.s32),
                          ProfileForm(
                            formKey: _formKey,
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            onUpdate: _handleUpdateProfile,
                            isLoading: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  // Fake data generation for UI testing
  UserEntity _generateFakeUser() {
    return UserEntity(
      id: 1,
      firstName: 'Ahmed',
      lastName: 'Al-Rashid',
      email: 'ahmed.alrashid@example.com',
      phone: '+961 3 1234567',
      role: UserRole.admin,
      notificationChannel: NotificationChannel.email,
      address: 'Beirut, Hamra Street, Building 123',
      isOnline: true,
      verifiedAt: DateTime.now().subtract(const Duration(days: 30)),
      currentLat: 33.8938,
      currentLng: 35.5018,
      countryId: 1,
      country: CountryEntity(
        id: 1,
        name: const CountryName(ar: 'لبنان', en: 'Lebanon'),
        code: 'LB',
        callingCode: '+961',
        currencyCode: 'LBP',
        currencySymbol: 'L.L',
        currencySmallestUnit: 'piaster',
        currencyFactor: 100,
        isActive: true,
      ),
      cityId: 1,
      city: CityEntity(
        id: 1,
        name: const CityName(ar: 'بيروت', en: 'Beirut'),
        countryId: 1,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }
}
