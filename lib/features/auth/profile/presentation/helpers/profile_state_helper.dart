import '../../../login/domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';

/// Returns the [UserEntity] from a [ProfileState] when profile is loaded.
UserEntity? getProfileUserFromState(ProfileState state) {
  if (state is ProfileLoaded) return state.user;
  return null;
}
