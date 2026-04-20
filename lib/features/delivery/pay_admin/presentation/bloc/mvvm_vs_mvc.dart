// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// ////////////////////////////////////////////////////////////
// /// ======================= MVC ========================= ///
// ////////////////////////////////////////////////////////////

// /// MVC Flow:
// /// View → Controller → API
// ///
// /// Controller handles:
// /// - UI logic
// /// - Business logic
// /// - API calls (everything in one place)

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<HomeController>(
//       init: HomeController(),
//       builder: (controller) {
//         return Scaffold(
//           body: Center(
//             child: TextButton(
//               onPressed: controller.increase,
//               child: Text(controller.counter.toString()),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class HomeController extends GetxController {
//   int counter = 0;

//   void increase() {
//     counter++;
//     update();
//   }

//   Future<void> getCounterFromApi() async {
//     // API call directly inside controller (MVC style)
//     await Crud().getData(
//       AppLinks.getCounterLink,
//       headers: defaultHeaders,
//     );
//   }
// }

// ////////////////////////////////////////////////////////////
// /// ======================= MVVM ======================== ///
// ////////////////////////////////////////////////////////////

// /// MVVM Flow:
// /// View → ViewModel (Controller) → Repository → API
// ///
// /// Key Idea:
// /// ViewModel DOES NOT call API directly
// /// It depends on Repository

// /// Repository = Data layer (API only)
// class ClientRepo {
//   Future<int> getCounterFromApi() async {
//     final response = await anyHttp.getData(
//       AppLinks.getCounterLink,
//       headers: defaultHeaders,
//     );

//     return response['counter'] ?? 0;
//   }
// }

// /// ViewModel (Controller in GetX)
// /// Handles:
// /// - State
// /// - Business logic
// /// Uses Repo instead of calling API directly
// class ClientController extends GetxController {
//   final ClientRepo repo;

//   ClientController(this.repo);

//   int counter = 0;

//   void increase() {
//     counter++;
//     update();
//   }

//   Future<void> loadCounter() async {
//     counter = await repo.getCounterFromApi();
//     update();
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     loadCounter();
//   }
// }

// /// View (UI only)
// class ClientScreen extends StatelessWidget {
//   const ClientScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ClientController>(
//       init: ClientController(ClientRepo()),
//       builder: (controller) {
//         return Scaffold(
//           body: Center(
//             child: TextButton(
//               onPressed: controller.increase,
//               child: Text(controller.counter.toString()),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// ////////////////////////////////////////////////////////////
// /// ============ Feature Example (MVVM usage) ============ ///
// ////////////////////////////////////////////////////////////

// /// ViewModel depends on Repository (NOT another controller)
// class CreateSaleInvoiceController extends GetxController {
//   final ClientRepo repo;

//   CreateSaleInvoiceController(this.repo);

//   Future<void> createSaleInvoice() async {
//     int counter = await repo.getCounterFromApi();

//     // business logic here
//     print("Creating invoice with counter: $counter");
//   }
// }

// class CreateSaleInvoiceScreen extends StatelessWidget {
//   const CreateSaleInvoiceScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<CreateSaleInvoiceController>(
//       init: CreateSaleInvoiceController(ClientRepo()),
//       builder: (controller) {
//         return Scaffold(
//           body: Center(
//             child: ElevatedButton(
//               onPressed: controller.createSaleInvoice,
//               child: const Text("Create Invoice"),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }