import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LogInPage extends StatelessWidget {
  const LogInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LogIn', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Center(
        child: Text('LogIn Feature', style: TextStyle(fontSize: 24.sp)),
      ),
    );
  }
}
